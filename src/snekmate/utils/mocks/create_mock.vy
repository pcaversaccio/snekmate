# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `create` Module Reference Implementation
@custom:contract-name create_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `create` module.
# @notice Please note that the `create` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import create as c1


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
def deploy_create(init_code: Bytes[8_192]) -> address:
    """
    @dev Deploys a new contract via calling the `CREATE` opcode and
         using the creation bytecode `init_code` and `msg.value` as
         inputs.
    @notice Please note that the `init_code` represents the complete
            contract creation code, i.e. including the ABI-encoded
            constructor arguments, and if `msg.value` is non-zero,
            `init_code` must have a `payable` constructor.
    @param init_code The maximum 8,192-byte contract creation bytecode.
    @return address The 20-byte address where the contract was deployed.
    """
    return c1._deploy_create(init_code)


@external
@view
def compute_create_address_self(nonce: uint256) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE` opcode.
    @param nonce The 32-byte account nonce of this contract.
    @return address The 20-byte address where a contract will be stored.
    """
    return c1._compute_create_address_self(nonce)


@external
@pure
def compute_create_address(deployer: address, nonce: uint256) -> address:
    """
    @dev Returns the address where a contract will be stored
         if deployed via `deployer` using the `CREATE` opcode.
         For the specification of the Recursive Length Prefix (RLP)
         encoding scheme, please refer to p. 19 of the Ethereum
         Yellow Paper (https://ethereum.github.io/yellowpaper/paper.pdf)
         and the Ethereum Wiki (https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/).
         For further insights also, see the following issue:
         https://github.com/transmissions11/solmate/issues/207.

         Based on the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md)
         specification, all contract accounts on the Ethereum mainnet
         are initiated with `nonce = 1`. Thus, the first contract address
         created by another contract is calculated with a non-zero nonce.
    @param deployer The 20-byte deployer address.
    @param nonce The 32-byte account nonce of the deployer address.
    @return address The 20-byte address where a contract will be stored.
    """
    return c1._compute_create_address(deployer, nonce)
