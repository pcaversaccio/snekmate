# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Signature Message Hash Utility Functions
@custom:contract-name message_hash_utils
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to generate message hashes that conform
        to the EIP-191 (https://eips.ethereum.org/EIPS/eip-191) as well as
        EIP-712 (https://eips.ethereum.org/EIPS/eip-712) specifications. The
        implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MessageHashUtils.sol.
"""


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@internal
@pure
def _to_eth_signed_message_hash(hash: bytes32) -> bytes32:
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
    return keccak256(concat(b"\x19Ethereum Signed Message:\n32", hash))


@internal
@view
def _to_data_with_intended_validator_hash_self(data: Bytes[1_024]) -> bytes32:
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
    return self._to_data_with_intended_validator_hash(self, data)


@internal
@pure
def _to_data_with_intended_validator_hash(validator: address, data: Bytes[1_024]) -> bytes32:
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
    return keccak256(concat(x"1900", convert(validator, bytes20), data))


@internal
@pure
def _to_typed_data_hash(domain_separator: bytes32, struct_hash: bytes32) -> bytes32:
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
    return keccak256(concat(x"1901", domain_separator, struct_hash))
