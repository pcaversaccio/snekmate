// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

interface IP256 {
    function verify_sig(
        bytes32 hash,
        uint256 r,
        uint256 s,
        uint256 qx,
        uint256 qy
    ) external view returns (bool);
}
