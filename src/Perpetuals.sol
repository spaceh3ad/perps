// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {LiquidityProvider} from "./LiquidityProvider.sol";
import "./lib/Library.sol";

import {console2} from "forge-std/Test.sol";

contract Perpetuals is LiquidityProvider {
    using EnumerableSet for EnumerableSet.UintSet;
    uint256 _idCounter = 1;

    mapping(uint256 => Position) public positionInfo;

    // accept only positions with > 0.0001 btc
    modifier isAlowedSize(uint256 _psize) {
        if (_psize < MIN_POSITION || _psize > MAX_POSITION) {
            revert PositionSizeError(_psize);
        }
        _;
    }

    function openPosition(
        uint256 _psize,
        bool _direction
    ) public isAlowedSize(_psize) returns (uint256, uint256) {
        uint256 _collateral = liquidityProvided[msg.sender].free;
        uint256 _entryPrice = 28000 * 10 ** usdc.decimals();

        uint256 leverage = (
            ((_entryPrice * _psize * MAX_LEVERAGE) / _collateral)
        ) / 10 ** BTC.decimals();

        if (leverage > MAX_LEVERAGE) {
            revert MaxLeverageError(MAX_LEVERAGE, leverage);
        } else if (leverage < MIN_LEVERAGE) {
            revert MinLeverageError(MIN_LEVERAGE, leverage);
        }

        _lockLiquidty(msg.sender, _collateral);

        positionInfo[_idCounter] = Position({
            owner: msg.sender,
            size: _psize,
            entryPrice: _entryPrice,
            directions: _direction
        });

        _idCounter += 1;

        return (_entryPrice, _idCounter);
    }

    function increasePositionSize(uint256 _id, uint256 _amount) external {
        uint256 _free = liquidityProvided[positionInfo[_id].owner].free;
        if (_free < _amount) {
            revert InsufficientLiquidity(_amount);
        }

        Position storage position = positionInfo[_id];
        if (position.owner != msg.sender) {
            revert PermissionDenied();
        }

        position.size += _amount;
    }

    // function closePosition(uint256 _positionId) public {
    //     if (_positions.contains(_positionId)) {
    //         revert InvalidPosition(_positionId);
    //     }
    //     _positions.remove(_positionId);
    // }

    function _liquidatePosition(uint256 _positionId) internal {
        // TODO: liquidate position
        // _positions.remove(_positionId);
    }

    function liquidationPrice(
        uint256 size, // btc position size
        uint256 entryPrice, // btc price at entry
        // bool direction, // true for long, false for short
        uint256 collateral // usdc collateral
    ) public view returns (uint256 _liquidationPrice) {
        // TODO: short/long logic
        uint256 borrowedAmount = (size * entryPrice) / 10 ** BTC.decimals();
        _liquidationPrice = (((borrowedAmount - ((collateral * 1050) / 1000)) /
            size) * 10 ** BTC.decimals());
    }

    function getPrice() public view returns (uint256 _price) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 price = (uint256(sqrtPriceX96) ** 2 * 10 ** BTC.decimals()) >>
            (96 * 2);
        return price;
    }
}
