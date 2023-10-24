// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "./Interfaces.sol";

address constant BTC_TOKEN = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
address constant USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

// USDC/WBTC pool
address constant POOL = 0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35;

// max leverage
uint256 constant MAX_LEVERAGE = 10_000; // max leverage is 100

// liquidation threshold
uint256 constant LIQUIDATION_FEE = 5000; // 5%

// denumerator for collateral ratio (allow minimum of 0.0001 BTC)
uint256 constant DENOMINATOR = 10 ** 16;

IERC20 constant BTC = IERC20(BTC_TOKEN);
IERC20 constant USDC = IERC20(USDC_TOKEN);

struct Position {
    address owner;
    uint256 size; // btc amount that we buy
    uint256 entryPrice;
    uint256 liquidationPrice;
    uint256 lastUpdated;
    bool directions; // true for long, false for short
}

library Utils {
    function getPrice() internal view returns (uint256 _price) {
        (, bytes memory _data) = POOL.staticcall(
            abi.encodeWithSignature("slot0()")
        );
        (uint160 sqrtPriceX96, , , , , , ) = abi.decode(
            _data,
            (uint160, int24, uint16, uint16, uint16, uint8, bool)
        );
        uint256 price = (uint256(sqrtPriceX96) ** 2 * 10 ** 8) >> (96 * 2); // why 8?
        return price;
    }

    function liquidationPrice(
        uint256 size, // btc position size
        uint256 entryPrice, // btc price at entry
        bool direction, // true for long, false for short
        uint256 collateral // usdc collateral
    ) public view returns (uint256 _liquidationPrice) {
        console2.log(size, entryPrice, collateral);

        // collateral w usdc z 6 decimals,
        // size w btc z 18 decimals

        // if collateral is close to value of position + threshold then liquidate
        uint256 borrowedAmount = (size * entryPrice) / DENOMINATOR;
        console2.log("borrowed amount: ", borrowedAmount);

        _liquidationPrice = ((borrowedAmount - (collateral * 105) / size) /
            10 ** 2); // divide by 100 for fee

        console2.log("liquidation price: ", _liquidationPrice);
    }
}
