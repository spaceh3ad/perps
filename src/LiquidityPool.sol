// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {USDC} from "./lib/Library.sol";

contract LiquidityPool {
    // we allow only USDC as collateral
    mapping(address => uint256) public liquidityProvided;

    function addLiquidity(uint256 _amount) external {
        USDC.transferFrom(msg.sender, address(this), _amount);
        liquidityProvided[msg.sender] += _amount;
    }

    function removeLiquidity(uint256 _amount) external {
        liquidityProvided[msg.sender] -= _amount;
        USDC.transfer(msg.sender, _amount);
    }
}
