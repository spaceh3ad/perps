// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../../src/lib/Library.sol";

import {Perpetuals} from "../../src/Perpetuals.sol";
import {LiquidityProvider} from "../../src/LiquidityProvider.sol";

contract PerpetualsTest is Test {
    Perpetuals public perp;

    address alice = address(123);
    address bob = address(321);

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
        address _account,
        bool _direction
    ) public {
        _openPosition(_amount, _psize, _account, _direction);
    }

    // function wrappIncreasePosition(
    //     address _account,
    //     uint256 _collateral,
    //     uint256 _psize
    // ) public useAccount(_account) {
    //     _increasePosition(_account, _amount, _psize, _increaseCollateral);
    // }

    /////////////////////////////////////////

    ////////// Internal /////////////////////
    function _openPosition(
        uint256 _amount,
        uint256 _psize,
        address _account,
        bool _direction
    ) internal useAccount(_account) returns (uint256 _entryPrice, uint256 _id) {
        deal(address(usdc), _account, _amount);
        usdc.approve(address(perp), _amount);

        perp.addLiquidity(_amount);
        (_entryPrice, _id) = perp.openPosition(_psize, _direction);
    }

    function _increasePosition(
        address _account,
        uint256 _id,
        uint256 _psize,
        uint256 _collateral
    ) internal useAccount(_account) {
        if (_collateral > 0) {
            deal(address(usdc), _account, _collateral);
            usdc.approve(address(perp), _collateral);
            perp.increasePositionCollateral(_id, _collateral);
        } else {
            perp.increasePositionSize(_id, _psize);
        }
    }

    //////////// Integration Tests ///////////////////

    function test_openPosition() public {
        uint256 _entryPrice = 28000 * 10 ** usdc.decimals(); // 28000 USDC
        uint256 _collateral = 100 * 10 ** usdc.decimals(); // 100 USDC
        uint256 _psize = 2 * 10 ** (btc.decimals() - 2); // 0.02 BTC
        uint256 _leverage;

        // TEST: should allow to open position for long
        (, uint256 _id) = _openPosition(_collateral, _psize, alice, true);
        (address _owner, uint256 _size, , , bool _direction) = perp
            .positionInfo(_id);
        assert(_owner == alice && _size == _psize && _direction == true);
        // END TEST

        // TEST: should allow to open position for short
        (, _id) = _openPosition(_collateral, _psize, alice, false);
        (_owner, _size, , , _direction) = perp.positionInfo(_id);
        assert(_owner == alice && _size == _psize && _direction == false);
        // END TEST

        // TEST: should not allow to open position with too small collateral
        uint256 _tooLessCollateral = 10 ** (usdc.decimals() - 1); // 1 USDC
        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientLiquidity.selector,
                _tooLessCollateral
            )
        );
        this.wrappOpenPosition(_tooLessCollateral, _psize, alice, true);
        // END TEST

        // TEST: should not allow to open position with leverage > MAX_LEVERAGE
        // assume psize 10 BTC collateral 100 USDC and BTC price 28000 USDC
        _psize = 10 * 10 ** btc.decimals(); // 10 BTC
        _leverage = getLeverage(_entryPrice, _psize, _collateral);

        vm.expectRevert(
            abi.encodeWithSelector(
                MaxLeverageError.selector,
                MAX_LEVERAGE,
                _leverage
            )
        );
        this.wrappOpenPosition(_collateral, _psize, alice, true);
        // END TEST

        // TEST: should not allow to open position with leverage < MIN_LEVERAGE
        _psize = 1 * 10 ** (btc.decimals() - 4); // 0.0001 BTC
        _leverage = getLeverage(_entryPrice, _psize, _collateral);

        vm.expectRevert(
            abi.encodeWithSelector(
                MinLeverageError.selector,
                MIN_LEVERAGE,
                _leverage
            )
        );
        this.wrappOpenPosition(_collateral, _psize, alice, true);
        // END TEST
    }

    function test_increasePosition() public {
        uint256 _entryPrice = 28000 * 10 ** usdc.decimals(); // 28000 USDC
        uint256 _collateral = 100 * 10 ** usdc.decimals(); // 100 USDC
        uint256 _psizeBase = 2 * 10 ** (btc.decimals() - 2); // 0.02 BTC
        uint256 _psize = 1 * 10 ** (btc.decimals() - 1); // 0.1 BTC

        uint256 _leverage;

        // TEST: should allow to increase position size
        (, uint256 _id) = _openPosition(_collateral, _psizeBase, alice, true);

        _increasePosition(alice, _id, _psize, 0);
        (, uint256 _cumPsize, , , ) = perp.positionInfo(_id);
        assert(_cumPsize == _psizeBase + _psize);
        // END TEST

        // TEST: should allow to increase position collateral
        _leverage = getLeverage(_entryPrice, _cumPsize, _collateral);
        deal(address(usdc), alice, _collateral);
        usdc.approve(address(perp), _collateral);
        _increasePosition(alice, _id, 0, _collateral);
        (, , , uint256 _increasedCollateral, ) = perp.positionInfo(_id);
        assert(_increasedCollateral == _collateral * 2);

        // the leverage should change to be lower
        // notice we already opened position with 0.02 BTC and increased it with 0.1 BTC
        uint256 _leverageAfter = getLeverage(
            _entryPrice,
            _cumPsize,
            _increasedCollateral
        );
        assert(_leverageAfter < _leverage);
        // END TEST

        // TEST: should not allow to increase position collateral to reach leverage < MIN_LEVERAGE
        uint256 _tooMuchCollateral = 1_000 * usdc.decimals();
        (, _id) = _openPosition(_collateral, _psizeBase, bob, true);
        _leverage = getLeverage(
            _entryPrice,
            _psizeBase,
            _collateral + _tooMuchCollateral
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                MaxLeverageError.selector,
                MAX_LEVERAGE,
                _leverage
            )
        );
        _increasePosition(bob, _id, 0, _tooMuchCollateral);
        // END TEST

        // TEST: should not allow to increase position size to reach leverage > MAX_LEVERAGE
        uint256 _tooMuchPsize = 1 * 10 ** (btc.decimals()); // 1 BTC
        (, _id) = _openPosition(_collateral, _psizeBase, alice, true);

        _leverage = getLeverage(
            _entryPrice,
            _psizeBase + _tooMuchPsize,
            _collateral
        );
        console2.log("Leverage: ", _leverage);
        vm.expectRevert(
            abi.encodeWithSelector(
                MaxLeverageError.selector,
                MAX_LEVERAGE,
                _leverage
            )
        );

        _increasePosition(alice, _id, _tooMuchPsize, 0);
        // END TEST

        // TEST: should not allow to increase someone else postion size
        vm.expectRevert(PermissionDenied.selector);
        _increasePosition(bob, _id, _psize, 0);
        // END TEST

        // TEST: should not be possible to remove collateral from position
        vm.expectRevert(
            abi.encodeWithSelector(InsufficientLiquidity.selector, _collateral)
        );
        vm.prank(alice);
        perp.removeLiquidity(_collateral);
    }

    function test_closePosition() public {}
}
