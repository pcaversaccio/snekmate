# pragma version ~=0.4.0rc5
"""
@title `signature_checker` Module Reference Implementation
@custom:contract-name signature_checker_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `signature_checker` module.
# @notice Please note that the `signature_checker`
# module is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import signature_checker as sc


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) the `external` getter
# function `IERC1271_ISVALIDSIGNATURE_SELECTOR` from the
# `signature_checker` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: sc.IERC1271_ISVALIDSIGNATURE_SELECTOR


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
@view
def is_valid_signature_now(signer: address, hash: bytes32, signature: Bytes[65]) -> bool:
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
    return sc._is_valid_signature_now(signer, hash, signature)


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
    @param signer The 20-byte signer address.
    @param hash The 32-byte message digest that was signed.
    @param signature The maximum 65-byte signature of `hash`.
    @return bool The verification whether `signature` is valid
            for the provided data.
    """
    return sc._is_valid_ERC1271_signature_now(signer, hash, signature)
