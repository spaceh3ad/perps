// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/lib/Library.sol";

import {Perpetuals} from "../src/Perpetuals.sol";
import {LiquidityProvider} from "../src/LiquidityProvider.sol";

contract PerpetualsTest is Test {
    Perpetuals public perp;

    address alice = address(521);

    function setUp() public {
        perp = new Perpetuals();
    }

    function _openPosition(
        uint256 _amount,
        uint256 _psize
    ) internal returns (uint256, uint256) {
        deal(address(usdc), alice, _amount);
        vm.startPrank(alice);
        usdc.approve(address(perp), _amount);
        perp.addLiquidity(_amount);
        return perp.openPosition(_psize, true);
    }

    function wrappOpenPosition(uint256 _amount, uint256 _psize) public {
        _openPosition(_amount, _psize);
    }

    function test_fuzzOpenPosition(uint256 _collateral, uint256 _psize) public {
        vm.assume(
            _collateral >= MIN_COLLATERAL && // min 5 USDC collateral
                _psize >= MIN_POSITION && // MIN 0.0001 BTC
                _psize <= MAX_POSITION // MAX 500_000 BTC
        );
        uint256 _entryPrice = 28000 * 10 ** usdc.decimals();

        uint256 leverage = (
            ((_entryPrice * _psize * MAX_LEVERAGE) / _collateral)
        ) / 10 ** BTC.decimals();

        if (leverage > MAX_LEVERAGE) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    MaxLeverageError.selector,
                    MAX_LEVERAGE,
                    leverage
                )
            );
        } else if (leverage < MIN_LEVERAGE) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    MinLeverageError.selector,
                    MIN_LEVERAGE,
                    leverage
                )
            );
        }
        this.wrappOpenPosition(_collateral, _psize);
    }
}
