# pragma version ~=0.4.1
"""
@title `block_hash` Module Reference Implementation
@custom:contract-name block_hash_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `block_hash` module.
# @notice Please note that the `block_hash` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import block_hash as bh


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
def block_hash(block_number: uint256) -> bytes32:
    """
    @dev Returns the block hash for block number `block_number`.
    @notice For blocks older than 8,191 or future blocks (including
            the current one), returns zero, matching the `BLOCKHASH`
            behaviour. Furthermore, this function does verify if the
            history contract is deployed. If the history contract is
            undeployed, the function will fallback to the `BLOCKHASH`
            behaviour.
    @param block_number The 32-byte block number.
    @return bytes32 The 32-byte block hash for block number `block_number`.
    """
    return bh._block_hash(block_number)
