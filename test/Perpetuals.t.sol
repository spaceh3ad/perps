// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/lib/Library.sol";

import {Perpetuals} from "../src/Perpetuals.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";

contract PerpetualsTest is Test {
    LiquidityPool lp;
    Perpetuals perp;

    address alice = address(521);

    function setUp() public {
        lp = new LiquidityPool();
        perp = new Perpetuals(address(lp));
    }

    function test_getPrice() public {
        uint256 price = Utils.getPrice();
        console2.log(price);
    }

    function test_openPosition() public {
        uint256 amount = 400 * 10 ** 6; // amount of usdc
        deal(address(USDC), alice, amount);
        vm.startPrank(alice);
        USDC.approve(address(lp), amount);
        console2.log("block no before roll:", block.number);
        lp.addLiquidity(400 * 10 ** 6);
        perp.openPosition(1 ether, true);

        console2.log("block no after roll:", block.number);

        (
            address owner,
            uint256 size,
            uint256 entryPrice,
            uint256 liquidationPrice,
            uint256 lastUpdated,
            bool directions
        ) = perp.positionInfo(1);

        uint256 _liquidationPrice = Utils.liquidationPrice(
            1 ether,
            entryPrice,
            true,
            400 * 10 ** 6
        );

        console2.log(_liquidationPrice);
    }
}
