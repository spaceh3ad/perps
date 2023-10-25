// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./lib/Library.sol";

contract LiquidityProvider {
    mapping(address => Liquidity) public liquidityProvided;

    modifier liquidityCheck(address _sender, uint256 _amount) {
        if (liquidityProvided[_sender].free < _amount) {
            revert InsufficientLiquidity(_amount);
        }
        _;
    }

    function addLiquidity(uint256 _amount) external {
        if (_amount < MIN_COLLATERAL) {
            revert InsufficientLiquidity(_amount);
        }
        usdc.transferFrom(msg.sender, address(this), _amount);
        liquidityProvided[msg.sender] = Liquidity({free: _amount, locked: 0});
    }

    function removeLiquidity(
        uint256 _amount
    ) external liquidityCheck(msg.sender, _amount) {
        liquidityProvided[msg.sender].free -= _amount;
        usdc.transfer(msg.sender, _amount);
    }

    function _lockLiquidty(
        address _account,
        uint256 _amount
    ) internal liquidityCheck(_account, _amount) {
        liquidityProvided[_account].free -= _amount;
        liquidityProvided[_account].locked += _amount;
    }

    function _unlockLiquidity(
        address _account,
        uint256 _amount
    ) internal liquidityCheck(_account, _amount) {
        liquidityProvided[_account].free += _amount;
        liquidityProvided[_account].locked -= _amount;
    }
}
