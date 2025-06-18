# pragma version ~=0.4.3rc2
# pragma nonreentrancy off
"""
@title `create3` Module Reference Implementation
@custom:contract-name create3_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `create3` module.
# @notice Please note that the `create3` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import create3 as c3


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
def deploy_create3(salt: bytes32, init_code: Bytes[8_192]) -> address:
    """
    @dev Deploys a new contract via employing the `CREATE3` pattern
         (i.e. without an initcode factor) and using the salt value
         `salt`, the creation bytecode `init_code`, and `msg.value`
         as inputs.
    @notice Please note that the `init_code` represents the complete
            contract creation code, i.e. including the ABI-encoded
            constructor arguments, and if `msg.value` is non-zero,
            `init_code` must have a `payable` constructor.
    @param salt The 32-byte random value used to create the proxy
           contract address.
    @param init_code The maximum 8,192-byte contract creation bytecode.
    @return address The 20-byte address where the contract was deployed.
    """
    return c3._deploy_create3(salt, init_code)


@external
@view
def compute_create3_address_self(salt: bytes32) -> address:
    """
    @dev Returns the address where a contract will be stored if deployed
         via this contract using the `CREATE3` pattern (i.e. without an
         initcode factor). Any change in the `salt` value will result in
         a new destination address.
    @param salt The 32-byte random value used to create the proxy contract
           address.
    @return address The 20-byte address where a contract will be stored.
    """
    return c3._compute_create3_address_self(salt)


@external
@pure
def compute_create3_address(salt: bytes32, deployer: address) -> address:
    """
    @dev Returns the address where a contract will be stored if deployed
         via `deployer` using the `CREATE3` pattern (i.e. without an initcode
         factor). Any change in the `salt` value will result in a new destination
         address.
    @param salt The 32-byte random value used to create the proxy contract
           address.
    @param deployer The 20-byte deployer address.
    @return address The 20-byte address where a contract will be stored.
    """
    return c3._compute_create3_address(salt, deployer)
