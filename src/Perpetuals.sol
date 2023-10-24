// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./lib/Library.sol";
import "./lib/Errors.sol";

import {console2} from "forge-std/Test.sol";

contract Perpetuals {
    using EnumerableSet for EnumerableSet.UintSet;
    uint256 _idCounter = 1;

    mapping(uint256 => Position) public positionInfo;

    address immutable liquidityPool;

    constructor(address _liquidtyPool) {
        liquidityPool = _liquidtyPool;
    }

    function openPosition(uint256 size, bool direction) public {
        uint256 collateral = getCollateral(msg.sender);
        uint256 entryPrice = Utils.getPrice();

        if (((entryPrice * size) / collateral) / DENOMINATOR > MAX_LEVERAGE) {
            revert InsufficientCollateral(collateral, size);
        }
        positionInfo[_idCounter] = Position({
            owner: msg.sender,
            size: size,
            entryPrice: 28000 * 10 ** 6,
            liquidationPrice: 0,
            // liquidationPrice(
            //     size,
            //     entryPrice,
            //     direction,
            //     collateral
            // )
            lastUpdated: block.timestamp,
            directions: direction
        });
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

    //////////////// VIEWS ////////////////
    function getCollateral(address _user) public view returns (uint256) {
        (, bytes memory _data) = liquidityPool.staticcall(
            abi.encodeWithSignature("liquidityProvided(address)", _user)
        );

        return abi.decode(_data, (uint256));
    }
}
