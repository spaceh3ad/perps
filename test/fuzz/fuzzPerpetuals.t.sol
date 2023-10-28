// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../../src/lib/Library.sol";

import {Perpetuals} from "../../src/Perpetuals.sol";
import {LiquidityProvider} from "../../src/LiquidityProvider.sol";

contract PerpetualsTest is Test {
    Perpetuals public perp;

    address alice = address(521);

    function setUp() public {
        perp = new Perpetuals();
    }

    /////// Modifiers //////////////////////
    modifier positionSize(uint256 _psize) {
        vm.assume(_psize >= MIN_POSITION && _psize <= MAX_POSITION);
        _;
    }

    modifier useAccount(address _account) {
        vm.assume(_account != address(0));
        vm.startPrank(_account);
        _;
        vm.stopPrank();
    }

    /////// Wrappers ///////////////////////
    function wrappOpenPosition(
        uint256 _amount,
        uint256 _psize,
        address _account
    ) public {
        _openPosition(_amount, _psize, _account);
    }

    function wrappIncreasePositionSize(
        uint256 _amount,
        uint256 _psize,
        address _account
    ) public useAccount(_account) {
        _increasePositionSize(_amount, _psize);
    }

    /////////////////////////////////////////

    ////////// Internal /////////////////////
    function _openPosition(
        uint256 _amount,
        uint256 _psize,
        address _account
    ) internal useAccount(_account) returns (uint256 _entryPrice, uint256 _id) {
        deal(address(usdc), _account, _amount);
        vm.startPrank(_account);
        usdc.approve(address(perp), _amount);

        perp.addLiquidity(_amount);
        (_entryPrice, _id) = perp.openPosition(_psize, Direction.LONG);
        console2.log("Opened position with: ", _entryPrice, _amount, _id);
    }

    function _increasePositionSize(uint256 _id, uint256 _psize) internal {
        perp.increasePositionSize(_id, _psize);
    }

    //////////// Fuzzing ///////////////////

    function test_fuzzOpenPosition(
        uint256 _collateral,
        uint256 _psize,
        address _account
    ) public positionSize(_psize) {
        vm.assume(
            _collateral >= MIN_COLLATERAL // min 5 USDC collateral
        );
        uint256 _entryPrice = 28000 * 10 ** usdc.decimals();

        uint256 _leverage = getLeverage(_entryPrice, _psize, _collateral);

        if (_leverage > MAX_LEVERAGE) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    MaxLeverageError.selector,
                    MAX_LEVERAGE,
                    _leverage
                )
            );
        } else if (_leverage < MIN_LEVERAGE) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    MinLeverageError.selector,
                    MIN_LEVERAGE,
                    _leverage
                )
            );
        }
        this.wrappOpenPosition(_collateral, _psize, _account);
    }

    function test_fuzzIncreasePosition(
        uint256 _psize,
        address _account
    ) public positionSize(_psize) {
        uint256 _psizeBase = 20000;
        uint256 _collateral = 10000000;
        (uint256 _entryPrice, uint256 _id) = _openPosition(
            _collateral,
            _psizeBase,
            _account
        );
        (, uint256 _size, , , ) = perp.positionInfo(_id);

        uint256 _leverage = getLeverage(_entryPrice, _psize, _collateral);

        console2.log("Expected Leverage: ", _leverage);

        if (_leverage > MAX_LEVERAGE) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    MaxLeverageError.selector,
                    MAX_LEVERAGE,
                    _leverage
                )
            );
        } else if (_leverage < MIN_LEVERAGE) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    MinLeverageError.selector,
                    MIN_LEVERAGE,
                    _leverage
                )
            );
        }

        this.wrappIncreasePositionSize(1, _psize, _account);
        // (, _size, , ) = perp.positionInfo(1);
        // assert(_size == _psize);
    }

    //////////////////////////////////////////////
}
