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
        }
        _;
    }

    /// @dev allow leverages in range [MIN_LEVERAGE, MAX_LEVERAGE]
    modifier isValidLeverage(
        uint256 _psize,
        uint256 _collateral,
        uint256 _entryPrice
    ) {
        console2.log(_psize, _collateral, _entryPrice);
        uint256 _leverage = (
            ((_entryPrice * _psize * MAX_LEVERAGE) / _collateral)
        ) / 10 ** BTC.decimals();

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
        returns (uint256)
    {
        uint256 _id = _idCounter;

        positionInfo[_id] = Position({
            owner: _owner,
            size: _psize,
            entryPrice: _entryPrice,
            directions: _direction
        });

        _positions.add(_id);
        _idCounter += 1;

        return _id;
    }

    function _increasePositionSize(
        uint256 _id,
        uint256 _psize
    )
        internal
        isAlowedSize(_psize + positionInfo[_id].size)
        isValidLeverage(
            _psize + positionInfo[_id].size,
            liquidityProvided[msg.sender].free,
            positionInfo[_id].entryPrice
        )
        isValidPosition(_id)
    {
        Position storage position = positionInfo[_id];

        // if (_free < _collateral) {
        //     revert InsufficientLiquidity(_collateral);
        // }

        if (position.owner != msg.sender) {
            revert PermissionDenied();
        }

        position.size += _psize;
    }

    function _increasePositionCollateral() internal {}

    function _closePosition(uint256 _positionId) internal {
        if (_positions.contains(_positionId)) {
            revert InvalidPosition(_positionId);
        }
        // TODO: close position
        // calc profit/loss
        _positions.remove(_positionId);
    }
}
