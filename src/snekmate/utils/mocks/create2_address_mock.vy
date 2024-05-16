# pragma version ~=0.4.0rc4
"""
@title `create2_address` Module Reference Implementation
@custom:contract-name create2_address_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `create2_address` module.
# @notice Please note that the `create2_address`
# module is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import create2_address as c2a


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
def compute_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE2` opcode.
         Any change in the `bytecode_hash` or `salt` values will
         result in a new destination address.
    @param salt The 32-byte random value used to create the contract
           address.
    @param bytecode_hash The 32-byte bytecode digest of the contract
           creation bytecode.
    @return address The 20-byte address where a contract will be stored.
    """
    return c2a._compute_address_self(salt, bytecode_hash)


@external
@pure
def compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via `deployer` using the `CREATE2` opcode.
         Any change in the `bytecode_hash` or `salt` values will
         result in a new destination address.
    @param salt The 32-byte random value used to create the contract
           address.
    @param bytecode_hash The 32-byte bytecode digest of the contract
           creation bytecode.
    @param deployer The 20-byte deployer address.
    @return address The 20-byte address where a contract will be stored.
    """
    return c2a._compute_address(salt, bytecode_hash, deployer)
