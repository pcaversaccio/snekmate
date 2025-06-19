# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Elliptic Curve Digital Signature Algorithm (ECDSA) Secp256k1-Based Functions
@custom:contract-name ecdsa
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to verify that a message was signed by
        the holder of the private key of a given address. All cryptographic
        calculations are based on the Ethereum-native secp256k1 elliptic curve
        (see https://en.bitcoin.it/wiki/Secp256k1). For verification functions
        based on the NIST P-256 elliptic curve (also known as secp256r1), see
        the {p256} contract. The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol.
@custom:security Signatures must not be used as unique identifiers since the
                 `ecrecover` EVM precompile allows for malleable (non-unique)
                 signatures (see EIP-2: https://eips.ethereum.org/EIPS/eip-2)
                 or signatures can be malleablised using EIP-2098:
                 https://eips.ethereum.org/EIPS/eip-2098.
"""


# @dev The malleability threshold used as part of the ECDSA
# verification function.
_MALLEABILITY_THRESHOLD: constant(uint256) = (
    57_896_044_618_658_097_711_785_492_504_343_953_926_418_782_139_537_452_191_302_581_570_759_080_747_168
)


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
def _recover_sig(hash: bytes32, signature: Bytes[65]) -> address:
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
    # 65-byte case: `(r,s,v)` standard signature.
    if sig_length == 65:
        r: uint256 = extract32(signature, empty(uint256), output_type=uint256)
        s: uint256 = extract32(signature, 32, output_type=uint256)
        v: uint256 = convert(slice(signature, 64, 1), uint256)
        return self._try_recover_vrs(hash, v, r, s)
    # 64-byte case: `(r,vs)` signature; see: https://eips.ethereum.org/EIPS/eip-2098.
    elif sig_length == 64:
        r: uint256 = extract32(signature, empty(uint256), output_type=uint256)
        vs: uint256 = extract32(signature, 32, output_type=uint256)
        return self._try_recover_r_vs(hash, r, vs)

    return empty(address)


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
    s: uint256 = vs & convert(max_value(int256), uint256)
    # We do not check for an overflow here, as the shift operation
    # `vs >> 255` results in `0` or `1`.
    v: uint256 = unsafe_add(vs >> 255, 27)
    return self._try_recover_vrs(hash, v, r, s)


@internal
@pure
def _try_recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Recovers the signer address from a message digest `hash`
         and the secp256k1 signature parameters `v`, `r`, and `s`.
    @notice All client implementations of the precompile `ecrecover`
            check if the value of `v` is `27` or `28`. The references
            for the different client implementations can be found here:
            https://github.com/ethereum/yellowpaper/pull/860. Thus,
            the signature check on the value of `v` is neglected.
    @param hash The 32-byte message digest that was signed.
    @param v The secp256k1 1-byte signature parameter `v`.
    @param r The secp256k1 32-byte signature parameter `r`.
    @param s The secp256k1 32-byte signature parameter `s`.
    @return address The recovered 20-byte signer address.
    """
    assert s <= _MALLEABILITY_THRESHOLD, "ecdsa: invalid signature `s` value"

    signer: address = ecrecover(hash, v, r, s)
    assert signer != empty(address), "ecdsa: invalid signature"

    return signer
