// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/lib/Library.sol";

import {LiquidityProvider} from "../src/LiquidityProvider.sol";

contract LiquidityPoolTest is Test {
    address public alice = address(521);
    LiquidityProvider public lp;

    function setUp() public {
        lp = new LiquidityProvider();
    }

    function test_addLiquidity() public {
        uint256 amount = 400 * 10 ** 6; // amount of usdc
        deal(address(usdc), alice, amount);
        vm.startPrank(alice);
        usdc.approve(address(lp), amount);
        lp.addLiquidity(400 * 10 ** 6);
        (uint256 _free, ) = lp.liquidityProvided(alice);
        assert(_free == 400 * 10 ** 6);
    }
}
