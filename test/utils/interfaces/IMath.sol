// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

interface IMath {
    function uint256_average(uint256 x, uint256 y) external pure returns (uint256);

    function int256_average(int256 x, int256 y) external pure returns (int256);

    function ceil_div(uint256 x, uint256 y) external pure returns (uint256);

    function signum(int256 x) external pure returns (int256);

    function mul_div(uint256 x, uint256 y, uint256 denominator, bool roundup) external pure returns (uint256);

    function log2(uint256 x, bool roundup) external pure returns (uint256);

    function log10(uint256 x, bool roundup) external pure returns (uint256);

    function log256(uint256 x, bool roundup) external pure returns (uint256);

    function wad_ln(int256 x) external pure returns (int256);

    function wad_exp(int256 x) external pure returns (int256);

    function cbrt(uint256 x, bool roundup) external pure returns (uint256);

    function wad_cbrt(uint256 x) external pure returns (uint256);
}
