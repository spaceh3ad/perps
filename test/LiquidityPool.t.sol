// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/lib/Library.sol";

import {LiquidityPool} from "../src/LiquidityPool.sol";

contract LiquidityPoolTest is Test {
    LiquidityPool lp;

    address alice = address(521);

    function setUp() public {
        lp = new LiquidityPool();
    }

    function test_addLiquidity() public {
        uint256 amount = 400 * 10 ** 6; // amount of usdc
        deal(address(USDC), alice, amount);
        vm.startPrank(alice);
        USDC.approve(address(lp), amount);
        lp.addLiquidity(400 * 10 ** 6);
        console2.log(lp.liquidityProvided(alice));
        assert(lp.liquidityProvided(alice) == 400 * 10 ** 6);
    }
}
