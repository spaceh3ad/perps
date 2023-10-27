// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../../src/lib/Library.sol";

import {LiquidityProvider} from "../../src/LiquidityProvider.sol";

contract UnitLiquidityPoolTest is Test {
    LiquidityProvider public lp;

    address alice = address(12345);

    uint256 amount = 10 * 10 ** usdc.decimals();

    function setUp() public {
        lp = new LiquidityProvider();
    }

    function _addLiquidity(uint256 _amount, address _user) internal {
        deal(address(usdc), _user, _amount);
        vm.startPrank(alice);
        usdc.approve(address(lp), _amount);
        lp.addLiquidity(_amount);
        vm.stopPrank();
    }

    function _removeLiquidty(uint256 _amount, address _user) internal {
        vm.prank(_user);
        lp.removeLiquidity(_amount);
    }

    ///@dev user should be able to addLiqudity
    function test_addLiquidity() public {
        _addLiquidity(amount, alice);
        (uint256 _free, ) = lp.liquidityProvided(alice);
        assert(_free == amount);
    }

    ///@dev user should be able to addLiqudity
    function test_removeLiquidity() public {
        _addLiquidity(amount, alice);
        _removeLiquidty(amount, alice);
        (uint256 _free, ) = lp.liquidityProvided(alice);
        assert(_free == 0);

        // should be not allowed to remove more than what is provided
        uint256 _tooMuchAmount = amount + 1;
        _addLiquidity(amount, alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientLiquidity.selector,
                _tooMuchAmount
            )
        );
        _removeLiquidty(_tooMuchAmount, alice);
    }
}
