// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.15;

interface IMerkleProofVerification {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) external pure returns (bool);
}
