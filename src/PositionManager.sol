// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./LiquidityProvider.sol";

using EnumerableSet for EnumerableSet.UintSet;

contract PositionManager is LiquidityProvider {
    uint256 _idCounter = 1;

    /// @dev enumerable set for storing all _positionId[s]
    EnumerableSet.UintSet internal _positions;

    /// @dev mapping of _positionId to Position
    mapping(uint256 => Position) public positionInfo;

    modifier increaseCounter() {
        _;
        _idCounter += 1;
    }

    /// @dev allow posiztion size in range [MIN_POSITION, MAX_POSITION]
    modifier isAlowedSize(uint256 _psize) {
        if (_psize < MIN_POSITION || _psize > MAX_POSITION) {
            revert PositionSizeError(_psize);
        }
        _;
    }

    /// @dev allow only valid positions
    modifier isValidPosition(uint256 _positionId) {
        if (!_positions.contains(_positionId)) {
            revert InvalidPosition(_positionId);
        } else if (positionInfo[_positionId].owner != msg.sender) {
            revert PermissionDenied();
        }
        _;
    }

    /// @dev allow leverages in range [MIN_LEVERAGE, MAX_LEVERAGE]
    modifier isValidLeverage(
        uint256 _psize,
        uint256 _collateral,
        uint256 _entryPrice
    ) {
        uint256 _leverage = getLeverage(_entryPrice, _psize, _collateral);
        if (_leverage > MAX_LEVERAGE) {
            revert MaxLeverageError(MAX_LEVERAGE, _leverage);
        } else if (_leverage < MIN_LEVERAGE) {
            revert MinLeverageError(MIN_LEVERAGE, _leverage);
        }
        _;
    }

    function _addPosition(
        address _owner,
        uint256 _psize,
        uint256 _collateral,
        uint256 _entryPrice,
        bool _direction
    )
        internal
        isValidLeverage(_psize, _collateral, _entryPrice)
        increaseCounter
        returns (uint256)
    {
        positionInfo[_idCounter] = Position({
            owner: _owner,
            size: _psize,
            entryPrice: _entryPrice,
            collateral: _collateral,
            directions: _direction
        });

        _positions.add(_idCounter);

        return _idCounter;
    }

    function _increasePositionSize(
        uint256 _id,
        uint256 _psize
    )
        internal
        isAlowedSize(_psize)
        isValidLeverage(
            _psize + positionInfo[_id].size,
            positionInfo[_id].collateral,
            positionInfo[_id].entryPrice
        )
        isValidPosition(_id)
    {
        Position storage position = positionInfo[_id];

        position.size += _psize;
    }

    function _increasePositionCollateral(
        uint256 _id,
        uint256 _collateral
    )
        internal
        isValidPosition(_id)
        isValidLeverage(
            positionInfo[_id].size,
            positionInfo[_id].collateral + _collateral,
            positionInfo[_id].entryPrice
        )
    {
        Position storage position = positionInfo[_id];

        liquidityProvided[positionInfo[_id].owner].free -= _collateral;
        liquidityProvided[positionInfo[_id].owner].locked += _collateral;

        position.collateral += _collateral;
    }

    function _closePosition(uint256 _positionId, int256 _profitLoss) internal {
        if (_profitLoss > 0) {
            // profit
            _unlockLiquidity(
                positionInfo[_positionId].owner,
                positionInfo[_positionId].collateral
            );
            liquidityProvided[positionInfo[_positionId].owner].free += uint256(
                _profitLoss
            );
        } else {
            // loss
            _unlockLiquidity(
                positionInfo[_positionId].owner,
                positionInfo[_positionId].collateral - uint256(-_profitLoss)
            );
        }

        _positions.remove(_positionId);
        delete positionInfo[_positionId];
    }

    function _liquidatePosition(
        uint256 _positionId,
        address _liquidator
    ) internal {
        uint256 _collateral = positionInfo[_positionId].collateral;

        // send liquidator 2.5% of collateral
        liquidityProvided[_liquidator].free +=
            uint256(_collateral * 1025) /
            1000;

        // protocol fee
        liquidityProvided[address(this)].free +=
            uint256(_collateral * 1025) /
            1000;

        liquidityProvided[positionInfo[_positionId].owner]
            .locked -= positionInfo[_positionId].collateral;

        _positions.remove(_positionId);
    }
}
