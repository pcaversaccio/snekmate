# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title ECDSA and EIP-1271 Signature Verification Functions
@custom:contract-name signature_checker
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice Signature verification helper functions that can be used
        instead of {ecdsa-_recover_sig} to seamlessly support both
        ECDSA secp256k1-based (see https://en.bitcoin.it/wiki/Secp256k1)
        signatures from externally-owned accounts (EOAs) as well as
        EIP-1271 (https://eips.ethereum.org/EIPS/eip-1271) signatures
        from smart contract wallets like Argent and Safe. For strict
        EIP-1271 verification, i.e. only valid EIP-1271 signatures are
        verified, the function `_is_valid_ERC1271_signature_now` can
        be called. The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol.
@custom:security Signatures must not be used as unique identifiers since the
                 `ecrecover` EVM precompile allows for malleable (non-unique)
                 signatures (see EIP-2: https://eips.ethereum.org/EIPS/eip-2)
                 or signatures can be malleablised using EIP-2098:
                 https://eips.ethereum.org/EIPS/eip-2098.
"""


# @dev We import the `ecdsa` module.
# @notice Please note that the `ecdsa` module
# is stateless and therefore does not require
# the `uses` keyword for usage.
from . import ecdsa


# @dev The 4-byte function selector of `isValidSignature(bytes32,bytes)`.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
IERC1271_ISVALIDSIGNATURE_SELECTOR: public(constant(bytes4)) = 0x1626BA7E


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
@view
def _is_valid_signature_now(signer: address, hash: bytes32, signature: Bytes[65]) -> bool:
    """
    @dev Checks if a signature `signature` is valid
         for a given `signer` and message digest `hash`.
         If the signer is a smart contract, the signature
         is validated against that smart contract using
         EIP-1271, otherwise it's validated using {ecdsa-_recover_sig}.
    @notice Unlike ECDSA signatures, contract signatures
            are revocable and the result of this function
            can therefore change over time. It could return
            `True` in block N and `False` in block N+1 (or the opposite).
    @param signer The 20-byte signer address.
    @param hash The 32-byte message digest that was signed.
    @param signature The maximum 65-byte signature of `hash`.
    @return bool The verification whether `signature` is valid
            for the provided data.
    @custom:security Since we avoid validating ECDSA signatures
                     when code is deployed at the signer's address,
                     it is safe if EIP-7377 (https://eips.ethereum.org/EIPS/eip-7377)
                     should be deployed one day.
    """
    # First check: ECDSA case.
    if not signer.is_contract:
        return ecdsa._recover_sig(hash, signature) == signer

    # Second check: EIP-1271 case.
    return self._is_valid_ERC1271_signature_now(signer, hash, signature)


@internal
@view
def _is_valid_ERC1271_signature_now(signer: address, hash: bytes32, signature: Bytes[65]) -> bool:
    """
    @dev Checks if a signature `signature` is valid
         for a given `signer` and message digest `hash`.
         The signature is validated using EIP-1271.
    @notice Unlike ECDSA signatures, contract signatures
            are revocable and the result of this function
            can therefore change over time. It could return
            `True` in block N and `False` in block N+1 (or the opposite).
    @param signer The 20-byte signer address.
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
    success, return_data = raw_call(
        signer,
        abi_encode(hash, signature, method_id=IERC1271_ISVALIDSIGNATURE_SELECTOR),
        max_outsize=32,
        is_static_call=True,
        revert_on_failure=False,
    )
    return (
        success
        and len(return_data) == 32
        and convert(return_data, bytes32) == convert(IERC1271_ISVALIDSIGNATURE_SELECTOR, bytes32)
    )
