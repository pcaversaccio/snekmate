// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.28;

interface ISignatureChecker {
    function IERC1271_ISVALIDSIGNATURE_SELECTOR()
        external
        pure
        returns (bytes4);

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
