# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `create2` Module Reference Implementation
@custom:contract-name create2_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `create2` module.
# @notice Please note that the `create2` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import create2 as c2


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
@payable
def deploy_create2(salt: bytes32, init_code: Bytes[8_192]) -> address:
    """
    @dev Deploys a new contract via calling the `CREATE2` opcode and
         using the salt value `salt`, the creation bytecode `init_code`,
         and `msg.value` as inputs.
    @notice Please note that the `init_code` represents the complete
            contract creation code, i.e. including the ABI-encoded
            constructor arguments, and if `msg.value` is non-zero,
            `init_code` must have a `payable` constructor.
    @param salt The 32-byte random value used to create the contract
           address.
    @param init_code The maximum 8,192-byte contract creation bytecode.
    @return address The 20-byte address where the contract was deployed.
    """
    return c2._deploy_create2(salt, init_code)


@external
@view
def compute_create2_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
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
    return c2._compute_create2_address_self(salt, bytecode_hash)


@external
@pure
def compute_create2_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
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
    return c2._compute_create2_address(salt, bytecode_hash, deployer)
