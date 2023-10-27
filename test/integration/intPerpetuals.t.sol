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

    uint256 entryPrice = 28000 * 10 ** usdc.decimals(); // 28000 USDC
    uint256 collateral = 100 * 10 ** usdc.decimals(); // 100 USDC
    uint256 psizeBase = 2 * 10 ** (btc.decimals() - 2); // 0.02 BTC
    uint256 psize = 1 * 10 ** (btc.decimals() - 1); // 0.1 BTC
    uint256 leverage;

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

    function wrappIncreasePosition(
        address _account,
        uint256 _id,
        uint256 _collateral,
        uint256 _psize
    ) public {
        _increasePosition(_account, _id, _collateral, _psize);
    }

    function wrapGeneric(
        bytes memory _data,
        address _account
    ) public useAccount(_account) returns (bytes memory) {
        (bool _success, bytes memory _rdata) = address(perp).call(_data);
        if (!_success) {
            return _rdata;
        }
    }

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
        // TEST: should allow to open position for long
        (, uint256 _id) = _openPosition(collateral, psize, alice, true);
        (address _owner, uint256 _size, , , bool _direction) = perp
            .positionInfo(_id);
        assert(_owner == alice && _size == psize && _direction == true);
        // END TEST

        // TEST: should allow to open position for short
        (, _id) = _openPosition(collateral, psize, alice, false);
        (_owner, _size, , , _direction) = perp.positionInfo(_id);
        assert(_owner == alice && _size == psize && _direction == false);
        // END TEST

        // TEST: should not allow to open position with too small collateral
        uint256 _tooLessCollateral = 10 ** (usdc.decimals() - 1); // 1 USDC
        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientLiquidity.selector,
                _tooLessCollateral
            )
        );
        this.wrappOpenPosition(_tooLessCollateral, psize, alice, true);
        // END TEST

        // TEST: should not allow to open position with leverage > MAX_LEVERAGE
        // assume psize 10 BTC collateral 100 USDC and BTC price 28000 USDC
        psize = 10 * 10 ** btc.decimals(); // 10 BTC
        leverage = getLeverage(entryPrice, psize, collateral);

        vm.expectRevert(
            abi.encodeWithSelector(
                MaxLeverageError.selector,
                MAX_LEVERAGE,
                leverage
            )
        );
        this.wrappOpenPosition(collateral, psize, alice, true);
        // END TEST

        // TEST: should not allow to open position with leverage < MIN_LEVERAGE
        psize = 1 * 10 ** (btc.decimals() - 4); // 0.0001 BTC
        leverage = getLeverage(entryPrice, psize, collateral);

        vm.expectRevert(
            abi.encodeWithSelector(
                MinLeverageError.selector,
                MIN_LEVERAGE,
                leverage
            )
        );
        this.wrappOpenPosition(collateral, psize, alice, true);
        // END TEST
    }

    function test_increasePosition() public {
        // TEST: should allow to increase position size
        console2.log("TEST: should allow to increase position size");
        (, uint256 _id) = _openPosition(collateral, psizeBase, alice, true);

        _increasePosition(alice, _id, psize, 0);
        (, uint256 _cumPsize, , , ) = perp.positionInfo(_id);
        assert(_cumPsize == psizeBase + psize);
        // END TEST

        // TEST: should allow to increase position collateral
        console2.log("TEST: should allow to increase position collateral");

        leverage = getLeverage(entryPrice, _cumPsize, collateral);
        deal(address(usdc), alice, collateral);
        usdc.approve(address(perp), collateral);
        _increasePosition(alice, _id, 0, collateral);
        (, , , uint256 _increasedCollateral, ) = perp.positionInfo(_id);
        assert(_increasedCollateral == collateral * 2);

        // the leverage should change to be lower
        // notice we already opened position with 0.02 BTC and increased it with 0.1 BTC
        uint256 _leverageAfter = getLeverage(
            entryPrice,
            _cumPsize,
            _increasedCollateral
        );
        assert(_leverageAfter < leverage);
        // END TEST

        // TEST: should not allow to increase position collateral to reach leverage < MIN_LEVERAGE
        console2.log(
            "TEST: should not allow to increase position collateral to reach leverage < MIN_LEVERAGE"
        );
        uint256 _tooMuchCollateral = 10_000 * 10 ** usdc.decimals();
        (, _id) = _openPosition(collateral, psizeBase, bob, true);
        leverage = getLeverage(
            entryPrice,
            psizeBase,
            collateral + _tooMuchCollateral
        );
        console2.log("Leverage: ", leverage);
        vm.expectRevert(
            abi.encodeWithSelector(
                MinLeverageError.selector,
                MIN_LEVERAGE,
                leverage
            )
        );
        this.wrappIncreasePosition(bob, _id, 0, _tooMuchCollateral);
        // END TEST

        // TEST: should not allow to increase position size to reach leverage > MAX_LEVERAGE
        console2.log(
            "TEST: should not allow to increase position size to reach leverage > MAX_LEVERAGE"
        );
        uint256 _tooMuchPsize = 1 * 10 ** (btc.decimals()); // 1 BTC
        (, _id) = _openPosition(collateral, psizeBase, alice, true);

        leverage = getLeverage(
            entryPrice,
            psizeBase + _tooMuchPsize,
            collateral
        );
        console2.log("Leverage: ", leverage);
        vm.expectRevert(
            abi.encodeWithSelector(
                MaxLeverageError.selector,
                MAX_LEVERAGE,
                leverage
            )
        );

        this.wrappIncreasePosition(alice, _id, _tooMuchPsize, 0);
        // END TEST

        // TEST: should not allow to increase someone else postion size
        console2.log(
            "TEST: should not allow to increase someone else postion size"
        );
        vm.expectRevert(PermissionDenied.selector);
        this.wrappIncreasePosition(bob, _id, psize, 0);
        // END TEST

        // TEST: should not be possible to remove collateral from position
        console2.log(
            "TEST: should not be possible to remove collateral from position"
        );
        vm.expectRevert(
            abi.encodeWithSelector(InsufficientLiquidity.selector, collateral)
        );
        // vm.startPrank(alice);
        this.wrapGeneric(
            abi.encodeWithSelector(perp.removeLiquidity.selector, collateral),
            alice
        );
        // perp.removeLiquidity(collateral);
        // vm.stopPrank();
    }

    function test_closePosition() public {
        (, uint256 _id) = _openPosition(collateral, psize, alice, true);
        uint256 _pnl = uint256(
            getPnL(entryPrice, perp.getPrice(), psize, true)
        );

        perp.closePosition(_id);
        (uint256 _liquidityAfter, ) = perp.liquidityProvided(alice);
        assert(_liquidityAfter == collateral + _pnl);
    }
}
