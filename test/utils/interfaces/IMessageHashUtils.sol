// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

interface IMessageHashUtils {
    function to_eth_signed_message_hash(bytes32 hash) external pure returns (bytes32);

    function to_data_with_intended_validator_hash_self(bytes calldata data) external view returns (bytes32);

    function to_data_with_intended_validator_hash(
        address validator,
        bytes calldata data
    ) external pure returns (bytes32);

    function to_typed_data_hash(bytes32 domainSeparator, bytes32 structHash) external pure returns (bytes32);
}
