// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

interface ISignatureChecker {
    function is_valid_signature_now(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) external view returns (bool);
}
