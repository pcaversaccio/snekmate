// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

interface IMerkleProofVerification {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) external pure returns (bool);

    function multi_proof_verify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) external pure returns (bool);
}
