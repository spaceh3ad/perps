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

    function addLiquidity(uint256 _amount) public {
        if (_amount < MIN_COLLATERAL) {
            revert InsufficientLiquidity(_amount);
        }
        _addLiquidity(msg.sender, _amount);
    }

    function removeLiquidity(
        uint256 _amount
    ) public liquidityCheck(msg.sender, _amount) {
        _removeLiquidty(msg.sender, _amount);
    }

    ////////////// internal //////////////////
    function _addLiquidity(address _account, uint256 _amount) internal {
        usdc.transferFrom(_account, address(this), _amount);
        if (liquidityProvided[_account].free == 0) {
            liquidityProvided[_account] = Liquidity({free: _amount, locked: 0});
        } else {
            liquidityProvided[_account].free += _amount;
        }
    }

    function _removeLiquidty(address _account, uint256 _amount) internal {
        if (_amount == liquidityProvided[_account].free) {
            delete liquidityProvided[_account];
        } else {
            liquidityProvided[_account].free -= _amount;
        }
        usdc.transfer(_account, _amount);
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

    // View functions
    function getPrice() public view returns (uint256 _price) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 price = (uint256(sqrtPriceX96) ** 2 * 10 ** btc.decimals()) >>
            (96 * 2);
        return price;
    }
}
