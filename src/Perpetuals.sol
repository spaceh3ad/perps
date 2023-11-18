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
        Direction _direction // true for long, false for short
    ) public isAlowedSize(_psize) returns (uint256 _entryPrice, uint256 _id) {
        uint256 _collateral = liquidityProvided[msg.sender].free;
        _entryPrice = 31_000 * 10 ** usdc.decimals();
        // _entryPrice = getPrice();
        _lockLiquidty(msg.sender, _collateral);
        _id = _addPosition(
            msg.sender,
            _psize,
            _collateral,
            _entryPrice,
            _direction
        );

        return (_entryPrice, _id);
    }

    function increasePositionSize(uint256 _id, uint256 _psize) external {
        _increasePositionSize(_id, _psize);
    }

    function increasePositionCollateral(
        uint256 _id,
        uint256 _collateral
    ) external {
        _addLiquidity(msg.sender, _collateral);
        _increasePositionCollateral(_id, _collateral);
    }

    function closePosition(
        uint256 _positionId
    ) public isValidPosition(_positionId) {
        uint256 _price = getPrice();

        int256 _profitLoss = getPnL(
            positionInfo[_positionId].entryPrice,
            _price,
            positionInfo[_positionId].size,
            positionInfo[_positionId].direction
        );

        if (
            _profitLoss < 0 &&
            (positionInfo[_positionId].collateral * 1050) / 1000 <
            uint256(-_profitLoss)
        ) {
            _liquidatePosition(_positionId, msg.sender, _profitLoss);
        } else {
            _closePosition(_positionId, _profitLoss);
        }
    }
}
