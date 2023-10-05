# pragma version ^0.3.10
"""
@title Elliptic Curve Digital Signature Algorithm (ECDSA) Functions
@custom:contract-name ECDSA
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to verify that a message was signed
        by the holder of the private key of a given address. Additionally,
        we provide helper functions to handle signed data in Ethereum
        contracts based on EIP-191: https://eips.ethereum.org/EIPS/eip-191.
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol.
@custom:security Signatures must not be used as unique identifiers since the
                 `ecrecover` EVM precompile allows for malleable (non-unique)
                 signatures (see EIP-2: https://eips.ethereum.org/EIPS/eip-2)
                 or signatures can be malleablised using EIP-2098:
                 https://eips.ethereum.org/EIPS/eip-2098.
"""


_MALLEABILITY_THRESHOLD: constant(bytes32) = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
_SIGNATURE_INCREMENT: constant(bytes32) = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF


@external
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
def recover_sig(hash: bytes32, signature: Bytes[65]) -> address:
    """
    @dev Recovers the signer address from a message digest `hash`
         and the signature `signature`.
    @notice WARNING: This function is vulnerable to a kind of
            signature malleability due to accepting EIP-2098
            compact signatures in addition to the traditional
            65-byte signature format. The potentially affected
            contracts are those that implement signature reuse
            or replay protection by marking the signature itself
            as used rather than the signed message or a nonce
            included in it. A user may take a signature that has
            already been submitted, submit it again in a different
            form, and bypass this protection. Also, see OpenZeppelin's
            security advisory for more information:
            https://github.com/OpenZeppelin/openzeppelin-contracts/security/advisories/GHSA-4h98-2769-gh6h.
    @param hash The 32-byte message digest that was signed.
    @param signature The secp256k1 64/65-byte signature of `hash`.
    @return address The recovered 20-byte signer address.
    """
    sig_length: uint256 = len(signature)
    # 65-byte case: r,s,v standard signature.
    if (sig_length == 65):
        r: uint256 = extract32(signature, empty(uint256), output_type=uint256)
        s: uint256 = extract32(signature, 32, output_type=uint256)
        v: uint256 = convert(slice(signature, 64, 1), uint256)
        return self._try_recover_vrs(hash, v, r, s)
    # 64-byte case: r,vs signature; see: https://eips.ethereum.org/EIPS/eip-2098.
    elif (sig_length == 64):
        r: uint256 = extract32(signature, empty(uint256), output_type=uint256)
        vs: uint256 = extract32(signature, 32, output_type=uint256)
        return self._try_recover_r_vs(hash, r, vs)
    else:
        return empty(address)


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
    return keccak256(concat(b"\x19Ethereum Signed Message:\n32", hash))


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
    return keccak256(concat(b"\x19\x01", domain_separator, struct_hash))


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
    return self._to_data_with_intended_validator_hash(self, data)


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
    return self._to_data_with_intended_validator_hash(validator, data)


@internal
@pure
def _recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Recovers the signer address from a message digest `hash`
         and the secp256k1 signature parameters `v`, `r`, and `s`.
    @param hash The 32-byte message digest that was signed.
    @param v The secp256k1 1-byte signature parameter `v`.
    @param r The secp256k1 32-byte signature parameter `r`.
    @param s The secp256k1 32-byte signature parameter `s`.
    @return address The recovered 20-byte signer address.
    """
    return self._try_recover_vrs(hash, v, r, s)


@internal
@pure
def _try_recover_r_vs(hash: bytes32, r: uint256, vs: uint256) -> address:
    """
    @dev Recovers the signer address from a message digest `hash`
         and the secp256k1 short signature fields `r` and `vs`.
    @notice See https://eips.ethereum.org/EIPS/eip-2098 for the
            compact signature representation.
    @param hash The 32-byte message digest that was signed.
    @param r The secp256k1 32-byte signature parameter `r`.
    @param vs The secp256k1 32-byte short signature field of `v` and `s`.
    @return address The recovered 20-byte signer address.
    """
    s: uint256 = vs & convert(_SIGNATURE_INCREMENT, uint256)
    # We do not check for an overflow here since the shift operation
    # `vs >> 255` results essentially in a `uint8` type (0 or 1) and
    # we use `uint256` as result type.
    v: uint256 = unsafe_add(vs >> 255, 27)
    return self._try_recover_vrs(hash, v, r, s)


@internal
@pure
def _try_recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Recovers the signer address from a message digest `hash`
         and the secp256k1 signature parameters `v`, `r`, and `s`.
    @notice All client implementations of the precompile `ecrecover`
            check if the value of `v` is 27 or 28. The references for
            the different client implementations can be found here:
            https://github.com/ethereum/yellowpaper/pull/860. Thus,
            the signature check on the value of `v` is neglected.
    @param hash The 32-byte message digest that was signed.
    @param v The secp256k1 1-byte signature parameter `v`.
    @param r The secp256k1 32-byte signature parameter `r`.
    @param s The secp256k1 32-byte signature parameter `s`.
    @return address The recovered 20-byte signer address.
    """
    assert s <= convert(_MALLEABILITY_THRESHOLD, uint256), "ECDSA: invalid signature `s` value"

    signer: address = ecrecover(hash, v, r, s)
    assert signer != empty(address), "ECDSA: invalid signature"

    return signer


@internal
@pure
def _to_data_with_intended_validator_hash(validator: address, data: Bytes[1_024]) -> bytes32:
    """
    @dev An `internal` helper function that returns an Ethereum
         signed data with `validator` as the intended validator
         and a maximum 1,024-byte payload `data`.
    @notice This function structures the data according to
            the version `0x00` of EIP-191:
            https://eips.ethereum.org/EIPS/eip-191#version-0x00.
    @param validator The 20-byte intended validator address.
    @param data The maximum 1,024-byte data to be signed.
    @return bytes32 The 32-byte Ethereum signed data.
    """
    return keccak256(concat(b"\x19\x00", convert(validator, bytes20), data))
