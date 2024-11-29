# pragma version ~=0.4.1b3
"""
@title `message_hash_utils` Module Reference Implementation
@custom:contract-name message_hash_utils_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `message_hash_utils` module.
# @notice Please note that the `message_hash_utils`
# module is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import message_hash_utils as mu


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@external
@pure
def to_eth_signed_message_hash(hash: bytes32) -> bytes32:
    """
    @dev Returns an Ethereum signed message from a 32-byte
         message digest `hash`.
    @notice This function returns a 32-byte hash that
            corresponds to the one signed with the JSON-RPC method:
            https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_sign.
            This method is part of EIP-191:
            https://eips.ethereum.org/EIPS/eip-191.
    @param hash The 32-byte message digest.
    @return bytes32 The 32-byte Ethereum signed message.
    """
    return mu._to_eth_signed_message_hash(hash)


@external
@view
def to_data_with_intended_validator_hash_self(data: Bytes[1_024]) -> bytes32:
    """
    @dev Returns an Ethereum signed data with this contract
         as the intended validator and a maximum 1,024-byte
         payload `data`.
    @notice This function structures the data according to
            the version `0x00` of EIP-191:
            https://eips.ethereum.org/EIPS/eip-191#version-0x00.
    @param data The maximum 1,024-byte data to be signed.
    @return bytes32 The 32-byte Ethereum signed data.
    """
    return mu._to_data_with_intended_validator_hash(self, data)


@external
@pure
def to_data_with_intended_validator_hash(validator: address, data: Bytes[1_024]) -> bytes32:
    """
    @dev Returns an Ethereum signed data with `validator` as
         the intended validator and a maximum 1,024-byte payload
         `data`.
    @notice This function structures the data according to
            the version `0x00` of EIP-191:
            https://eips.ethereum.org/EIPS/eip-191#version-0x00.
    @param validator The 20-byte intended validator address.
    @param data The maximum 1,024-byte data to be signed.
    @return bytes32 The 32-byte Ethereum signed data.
    """
    return mu._to_data_with_intended_validator_hash(validator, data)


@external
@pure
def to_typed_data_hash(domain_separator: bytes32, struct_hash: bytes32) -> bytes32:
    """
    @dev Returns an Ethereum signed typed data from a 32-byte
         `domain_separator` and a 32-byte `struct_hash`.
    @notice This function returns a 32-byte hash that
            corresponds to the one signed with the JSON-RPC method:
            https://eips.ethereum.org/EIPS/eip-712#specification-of-the-eth_signtypeddata-json-rpc.
            This method is part of EIP-712:
            https://eips.ethereum.org/EIPS/eip-712.
    @param domain_separator The 32-byte domain separator that is
           used as part of the EIP-712 encoding scheme.
    @param struct_hash The 32-byte struct hash that is used as
           part of the EIP-712 encoding scheme. See the definition:
           https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    @return bytes32 The 32-byte Ethereum signed typed data.
    """
    return mu._to_typed_data_hash(domain_separator, struct_hash)
