// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {LiquidityProvider} from "./LiquidityProvider.sol";
import {PositionManager} from "./PositionManager.sol";
import "./lib/Library.sol";

import {console2} from "forge-std/Test.sol";

contract Perpetuals is LiquidityProvider, PositionManager {
    // accept only positions with > 0.0001 btc

    function openPosition(
        uint256 _psize,
        bool _direction
    ) public isAlowedSize(_psize) returns (uint256 _entryPrice, uint256 _id) {
        uint256 _collateral = liquidityProvided[msg.sender].free;
        _entryPrice = 28000 * 10 ** usdc.decimals();
        // _entryPrice = getPrice();

        _lockLiquidty(msg.sender, _collateral);
        _id = _addPosition(
            msg.sender,
            _psize,
            _collateral,
            _entryPrice,
            _direction
        );

        return (_entryPrice, _idCounter);
    }

    function increasePosition(
        uint256 _id,
        uint256 _psize,
        bool _lockedCollateral
    ) external {
        console2.log(msg.sender);
        console2.log(positionInfo[_id].owner);
        console2.log(_id);
        if (_lockedCollateral) {
            // _increasePositionCollateral(_id, _psize);
        } else {
            _increasePositionSize(_id, _psize);
        }
    }

    function closePosition(uint256 _positionId) public {
        _closePosition(_positionId);
    }

    function _liquidatePosition(uint256 _positionId) internal {
        // TODO: liquidate position
        // _positions.remove(_positionId);
    }

    function liquidationPrice(
        uint256 size, // btc position size
        uint256 entryPrice, // btc price at entry
        bool direction, // true for long, false for short
        uint256 collateral // usdc collateral
    ) public view returns (uint256 _liquidationPrice) {
        uint256 borrowedAmount = (size * entryPrice) / 10 ** BTC.decimals();
        uint256 debt = 0;
        if (direction) {
            // long
            debt = borrowedAmount - ((collateral * 1050) / 1000);
        } else {
            // short
            debt = borrowedAmount + ((collateral * 1050) / 1000);
        }
        _liquidationPrice = (((borrowedAmount - ((collateral * 1050) / 1000)) /
            size) * 10 ** BTC.decimals());
    }
}
