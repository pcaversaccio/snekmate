// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.18;

interface IMath {
    function mul_div(
        uint256 x,
        uint256 y,
        uint256 denominator,
        bool roundup
    ) external pure returns (uint256);
}
