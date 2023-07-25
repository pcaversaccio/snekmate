// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface ISignatureChecker {
    function is_valid_signature_now(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bool);

    function is_valid_ERC1271_signature_now(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bool);
}
