# pragma version ~=0.4.1b5
"""
@title `ecdsa` Module Reference Implementation
@custom:contract-name ecdsa_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `ecdsa` module.
# @notice Please note that the `ecdsa` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import ecdsa as ec


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
    return ec._recover_sig(hash, signature)
