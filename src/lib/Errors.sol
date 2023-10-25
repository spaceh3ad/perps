// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

///////// Perpetual Errors /////////
error MaxLeverageError(uint256 maxLeverage, uint256 leverage);
error MinLeverageError(uint256 minLeverage, uint256 leverage);
error InvalidPosition(uint256 positionId);
error PositionSizeError(uint256 size);

///////// Liquidity Provider Errors /////////
error PermissionDenied();
error InsufficientLiquidity(uint256 liquidity);
