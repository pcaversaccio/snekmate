# pragma version ^0.3.10
"""
@title ECDSA and EIP-1271 Signature Verification Functions
@custom:contract-name SignatureChecker
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice Signature verification helper functions that can be used
        instead of `ECDSA.recover_sig` to seamlessly support both
        ECDSA signatures from externally-owned accounts (EOAs) as
        well as EIP-1271 (https://eips.ethereum.org/EIPS/eip-1271)
        signatures from smart contract wallets like Argent and Gnosis
        Safe. For strict EIP-1271 verification, i.e. only valid EIP-1271
        signatures are verified, the function `is_valid_ERC1271_signature_now`
        can be called. The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol.
@custom:security Signatures must not be used as unique identifiers since the
                 `ecrecover` EVM precompile allows for malleable (non-unique)
                 signatures (see EIP-2: https://eips.ethereum.org/EIPS/eip-2)
                 or signatures can be malleablised using EIP-2098:
                 https://eips.ethereum.org/EIPS/eip-2098.
"""


IERC1271_ISVALIDSIGNATURE_SELECTOR: public(constant(bytes4)) = 0x1626BA7E
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
@view
def is_valid_signature_now(signer: address, hash: bytes32, signature: Bytes[65]) -> bool:
    """
    @dev Checks if a signature `signature` is valid
         for a given `signer` and message digest `hash`.
         If the signer is a smart contract, the signature
         is validated against that smart contract using
         EIP-1271, otherwise it's validated using `ECDSA.recover_sig`.
    @notice Unlike ECDSA signatures, contract signatures
            are revocable and the result of this function
            can therefore change over time. It could return
            `True` in block N and `False` in block N+1 (or the opposite).
    @param hash The 32-byte message digest that was signed.
    @param signature The maximum 65-byte signature of `hash`.
    @return bool The verification whether `signature` is valid
            for the provided data.
    """
    # First check: ECDSA case.
    recovered: address = self._recover_sig(hash, signature)
    if (recovered == signer):
        return True

    # Second check: EIP-1271 case.
    return self._is_valid_ERC1271_signature_now(signer, hash, signature)


@external
@view
def is_valid_ERC1271_signature_now(signer: address, hash: bytes32, signature: Bytes[65]) -> bool:
    """
    @dev Checks if a signature `signature` is valid
         for a given `signer` and message digest `hash`.
         The signature is validated using EIP-1271.
    @notice Unlike ECDSA signatures, contract signatures
            are revocable and the result of this function
            can therefore change over time. It could return
            `True` in block N and `False` in block N+1 (or the opposite).
    @param hash The 32-byte message digest that was signed.
    @param signature The maximum 65-byte signature of `hash`.
    @return bool The verification whether `signature` is valid
            for the provided data.
    """
    return self._is_valid_ERC1271_signature_now(signer, hash, signature)


@internal
@view
def _is_valid_ERC1271_signature_now(signer: address, hash: bytes32, signature: Bytes[65]) -> bool:
    """
    @dev This `internal` function is equivalent to
         `is_valid_ERC1271_signature_now`, and can be used
         for strict EIP-1271 verification.
    @notice Unlike ECDSA signatures, contract signatures
            are revocable and the result of this function
            can therefore change over time. It could return
            `True` in block N and `False` in block N+1 (or the opposite).
    @param hash The 32-byte message digest that was signed.
    @param signature The maximum 65-byte signature of `hash`.
    @return bool The verification whether `signature` is valid
            for the provided data.
    """
    success: bool = empty(bool)
    return_data: Bytes[32] = b""
    # The following low-level call does not revert, but instead
    # returns `False` if the callable contract does not implement
    # the `isValidSignature` function. Since we perform a length
    # check of 32 bytes for the return data in the return expression
    # at the end, we also return `False` for EOA wallets instead
    # of reverting (remember that the EVM always considers a call
    # to an EOA as successful with return data `0x`). Furthermore,
    # it is important to note that an external call via `raw_call`
    # does not perform an external code size check on the target
    # address.
    success, return_data = \
        raw_call(signer, _abi_encode(hash, signature, method_id=IERC1271_ISVALIDSIGNATURE_SELECTOR), max_outsize=32, is_static_call=True, revert_on_failure=False)
    return (success and (len(return_data) == 32) and (convert(return_data, bytes32) == convert(IERC1271_ISVALIDSIGNATURE_SELECTOR, bytes32)))


@internal
@pure
def _recover_sig(hash: bytes32, signature: Bytes[65]) -> address:
    """
    @dev Sourced from {ECDSA-recover_sig}.
    @notice See {ECDSA-recover_sig} for the
            function docstring.
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


@internal
@pure
def _recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Sourced from {ECDSA-_recover_vrs}.
    @notice See {ECDSA-_recover_vrs} for the
            function docstring.
    """
    return self._try_recover_vrs(hash, v, r, s)


@internal
@pure
def _try_recover_r_vs(hash: bytes32, r: uint256, vs: uint256) -> address:
    """
    @dev Sourced from {ECDSA-_try_recover_r_vs}.
    @notice See {ECDSA-_try_recover_r_vs} for the
            function docstring.
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
    @dev Sourced from {ECDSA-_try_recover_vrs}.
    @notice See {ECDSA-_try_recover_vrs} for the
            function docstring.
    """
    assert s <= convert(_MALLEABILITY_THRESHOLD, uint256), "ECDSA: invalid signature `s` value"

    signer: address = ecrecover(hash, v, r, s)
    assert signer != empty(address), "ECDSA: invalid signature"

    return signer
