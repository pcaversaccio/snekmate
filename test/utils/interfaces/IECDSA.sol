// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

interface IECDSA {
    function recover_sig(bytes32 hash, bytes memory signature)
        external
        pure
        returns (address);

    function to_eth_signed_message_hash(bytes32 hash)
        external
        pure
        returns (bytes32);

    function to_typed_data_hash(bytes32 domainSeparator, bytes32 structHash)
        external
        pure
        returns (bytes32);
}
