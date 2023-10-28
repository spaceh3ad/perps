// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "./Interfaces.sol";
import "./Errors.sol";

address constant BTC_TOKEN = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
address constant USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

// USDC/WBTC pool
address constant POOL_ADDRES = 0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35;

// max leverage
uint256 constant MAX_LEVERAGE = 10000; // max leverage is 100
uint256 constant MIN_LEVERAGE = 10; // min leverage is 0.1

// min collateral
uint256 constant MIN_COLLATERAL = 5000000; // 50 USDC

// position size
uint256 constant MIN_POSITION = 10000; // 0.0001 btc
uint256 constant MAX_POSITION = 50000000000000; // 500_000 btc

// liquidation threshold
uint256 constant LIQUIDATION_FEE = 5000; // 5%

IERC20 constant btc = IERC20(BTC_TOKEN);
IERC20 constant usdc = IERC20(USDC_TOKEN);
LiquidityPool constant pool = LiquidityPool(POOL_ADDRES);

enum Direction {
    SHORT,
    LONG
}

struct Position {
    address owner;
    uint256 size; // btc amount that we buy
    uint256 entryPrice;
    uint256 collateral;
    Direction direction; // true for long, false for short
}
struct Liquidity {
    uint256 free;
    uint256 locked;
}

function getLeverage(
    uint256 _entryPrice,
    uint256 _psize,
    uint256 _collateral
) view returns (uint256 _leverage) {
    _leverage = ((((_entryPrice * _psize) / _collateral)) /
        10 ** usdc.decimals());
}

function getPnL(
    uint256 _entryPrice,
    uint256 _exitPrice,
    uint256 _psize,
    Direction _directions // long/short
) view returns (int256 _profitLoss) {
    int256 _decimals = int256(10 ** btc.decimals());
    int256 xPrice;
    int256 yPrice;

    if (_directions == Direction.LONG) {
        // long
        xPrice = int256(_exitPrice);
        yPrice = int256(_entryPrice);
    } else {
        // short
        xPrice = int256(_entryPrice);
        yPrice = int256(_exitPrice);
    }
    _profitLoss = ((xPrice - yPrice) * int256(_psize)) / _decimals;
}

function protocolFee(uint256 _PnL) pure returns (uint256) {
    return uint256(_PnL * 25) / 1000;
}

function liquidationPrice(
    uint256 size, // btc position size
    uint256 entryPrice, // btc price at entry
    Direction direction, // true for long, false for short
    uint256 collateral // usdc collateral
) view returns (uint256 _liquidationPrice) {
    uint256 borrowedAmount = (size * entryPrice) / 10 ** btc.decimals();
    if (direction == Direction.LONG) {
        // long
        _liquidationPrice = (((borrowedAmount - ((collateral * 1050) / 1000)) /
            size) * 10 ** btc.decimals());
    } else {
        // short
        _liquidationPrice = (((borrowedAmount + ((collateral * 1050) / 1000)) /
            size) * 10 ** btc.decimals());
    }
}
