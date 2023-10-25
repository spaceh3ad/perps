// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface LiquidityPool {
    function slot0()
        external
        view
        returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}

interface IERC20 {
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256);

    function approve(address _spender, uint256 _value) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    ) external returns (bool success);

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    ) external returns (bool success);

    function mint(address _to, uint256 _amount) external returns (bool);

    function mintingFinished() external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function pendingOwner() external view returns (address);

    function reclaimToken(address _token) external;

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);
}
