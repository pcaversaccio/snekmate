# @version ^0.3.4
"""
@title Elliptic Curve Digital Signature Algorithm (ECDSA) Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions can be used to verify that a message was signed
        by the holder of the private key of a given address. The implementation
        is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
"""

MALLEABILITY_THRESHOLD: constant(bytes32) = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
SIGNATURE_INCREMENT: constant(bytes32) = 0X7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

@internal
@pure
def _recover_sig(hash: bytes32, signature: Bytes[65]) -> address:
    """
    @dev Recover the signer address from a message digest `hash`
         and the signature `signature`.
    @param hash The message digest that was signed.
    @param signature The secp256k1 signature of `hash`.
    """
    if (len(signature) == 65):
        r: uint256 = extract32(signature, 0, output_type=uint256)
        s: uint256 = extract32(signature, 32, output_type=uint256)
        v: uint256 = convert(slice(signature, 64, 1), uint256)
        return self._try_recover_vrs(hash, v, r, s)
    elif (len(signature) == 64):
        r: uint256 = extract32(signature, 0, output_type=uint256)
        vs: uint256 = extract32(signature, 32, output_type=uint256)
        return self._try_recover_r_vs(hash, r, vs)
    else:
        return empty(address)


@internal
@pure
def _recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Recover the signer address from a message digest `hash`
         and the secp256k1 signature parameters `v`, `r`, and `s`.
    @param hash The message digest that was signed.
    @param v secp256k1 signature parameter `v`
    @param r secp256k1 signature parameter `r`
    @param s secp256k1 signature parameter `s`
    """
    signer: address = self._try_recover_vrs(hash, v, r, s)
    return signer


@internal
@pure
def _try_recover_r_vs(hash: bytes32, r: uint256, vs: uint256) -> address:
    """
    @dev Recover the signer address from a message digest `hash`
         and the secp256k1 short signature fields `r` and `vs`.
    @notice See https://eips.ethereum.org/EIPS/eip-2098 for the
            compact signature representation.
    @param hash The message digest that was signed.
    @param r The secp256k1 signature parameter `r`.
    @param vs The secp256k1 short signature field of `v` and `s`.
    """
    s: uint256 = vs & convert(SIGNATURE_INCREMENT, uint256)
    v: uint256 = shift(vs, -255) + 27
    return self._try_recover_vrs(hash, v, r, s)


@internal
@pure
def _try_recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Recover the signer address from a message digest `hash`
         and the secp256k1 signature parameters `v`, `r`, and `s`.
    @notice All client implementations of the precompile `ecrecover`
            check if the value of `v` is 27 or 28. The references for
            the different client implementations can be found here:
            https://github.com/ethereum/yellowpaper/pull/860. Thus,
            the signature check on the value of `v` is neglected.
    @param hash The message digest that was signed.
    @param v The secp256k1 signature parameter `v`.
    @param r The secp256k1 signature parameter `r`.
    @param s The secp256k1 signature parameter `s`.
    """
    if (s > convert(MALLEABILITY_THRESHOLD, uint256)):
        raise "ECDSA: invalid signature \'s\' value"

    signer: address = ecrecover(hash, v, r, s)
    if (signer == empty(address)):
        raise "ECDSA: invalid signature"
    
    return signer
