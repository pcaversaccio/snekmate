# pragma version ~=0.4.0b5
"""
@title Base64 Module Reference Implementation
@custom:contract-name CreateAddressMock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and initialise the `CreateAddress` module.
from .. import CreateAddress as ca
initializes: ca


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    ca.__init__()


@external
@view
def compute_address_rlp_self(nonce: uint256) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE` opcode.
    @param nonce The next 32-byte nonce of this contract.
    @return address The 20-byte address where a contract will be stored.
    """
    return ca._compute_address_rlp_self(nonce)


@external
@pure
def compute_address_rlp(deployer: address, nonce: uint256) -> address:
    """
    @dev Returns the address where a contract will be stored
         if deployed via `deployer` using the `CREATE` opcode.
         For the specification of the Recursive Length Prefix (RLP)
         encoding scheme, please refer to p. 19 of the Ethereum
         Yellow Paper (https://ethereum.github.io/yellowpaper/paper.pdf)
         and the Ethereum Wiki (https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp).
         For further insights also, see the following issue:
         https://github.com/transmissions11/solmate/issues/207.

         Based on the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md)
         specification, all contract accounts on the Ethereum mainnet
         are initiated with `nonce = 1`. Thus, the first contract address
         created by another contract is calculated with a non-zero nonce.
    @param deployer The 20-byte deployer address.
    @param nonce The next 32-byte nonce of the deployer address.
    @return address The 20-byte address where a contract will be stored.
    """
    return ca._compute_address_rlp(deployer, nonce)
