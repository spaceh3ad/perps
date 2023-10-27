// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test, console2} from "forge-std/Test.sol";
// import "../src/lib/Library.sol";

// import {LiquidityProvider} from "../src/LiquidityProvider.sol";

// contract LiquidityPoolTest is Test {
//     address public alice = address(521);
//     LiquidityProvider public lp;

//     function setUp() public {
//         lp = new LiquidityProvider();
//     }

//     modifier preSet(uint256 _amount, address _user) {
//         vm.assume(_user != address(0) && _amount > MIN_COLLATERAL);
//         vm.startPrank(_user);
//         _;
//         vm.stopPrank();
//     }

//     function _addLiquidity(uint256 _amount, address _user) internal {
//         deal(address(usdc), _user, _amount);
//         usdc.approve(address(lp), _amount);
//         lp.addLiquidity(_amount);
//     }

//     function _removeLiquidty(uint256 _amount) internal {
//         lp.removeLiquidity(_amount);
//     }

//     ///@dev user should be able to addLiqudity
//     function test_fuzzAddLiquidity(
//         uint256 _amount,
//         address _user
//     ) public preSet(_amount, _user) {
//         _addLiquidity(_amount, _user);
//         (uint256 _free, ) = lp.liquidityProvided(_user);
//         assert(_free == _amount);
//     }

//     ///@dev user should be able to addLiqudity
//     function test_fuzzRemoveLiquidity(
//         uint256 _amount,
//         address _user
//     ) public preSet(_amount, _user) {
//         _addLiquidity(_amount, _user);
//         _removeLiquidty(_amount);
//         (uint256 _free, ) = lp.liquidityProvided(alice);
//         assert(_free == 0);
//     }
// }
