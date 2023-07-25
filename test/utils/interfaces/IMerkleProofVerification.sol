// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface IMerkleProofVerification {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) external pure returns (bool);

    function multi_proof_verify(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] calldata leaves
    ) external pure returns (bool);
}
