// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.19;

interface IMath {
    function mul_div(
        uint256 x,
        uint256 y,
        uint256 denominator,
        bool roundup
    ) external pure returns (uint256);

    function uint256_average(
        uint256 x,
        uint256 y
    ) external pure returns (uint256);

    function int256_average(int256 x, int256 y) external pure returns (int256);

    function ceil_div(uint256 x, uint256 y) external pure returns (uint256);
}
