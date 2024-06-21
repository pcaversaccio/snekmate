# pragma version ~=0.4.0
"""
@title `p256` Module Reference Implementation
@custom:contract-name p256_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `p256` module.
# @notice Please note that the `p256` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import p256 as p2


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
def verify_sig(hash: bytes32, r: uint256, s: uint256, qx: uint256, qy: uint256) -> bool:
    """
    @dev Verifies the signature of a message digest `hash`
         based on the secp256r1 signature parameters `r` and
         `s`, and the public key coordinates `qx` and `qy`.
    @param hash The 32-byte message digest that was signed.
    @param r The secp256r1 32-byte signature parameter `r`.
    @param s The secp256r1 32-byte signature parameter `s`.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @return bool The verification whether the signature is
            authentic or not.
    """
    return p2._verify_sig(hash, r, s, qx, qy)
