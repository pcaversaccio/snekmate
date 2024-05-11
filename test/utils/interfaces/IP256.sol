// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

interface IP256 {
    function verify_sig(
        bytes32 hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) external view returns (bool);
}
