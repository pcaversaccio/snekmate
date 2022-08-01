# @version ^0.3.4
"""
@title `CREATE2` EVM Opcode Utility Functions for Address Calculations
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions can be used to compute in advance the address
        where a smart contract will be deployed. The implementation is
        inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol.
"""


_COLLISION_OFFSET: constant(bytes1) = 0xFF


@internal
@view
def _compute_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract. Any change in the `bytecode_hash`
         or `salt` values will result in a new destination address.
    @param salt The 32-bytes random value used to create the contract address.
    @param bytecode_hash The 32-bytes bytecode digest of the contract creation bytecode.
    """
    return self._compute_address(salt, bytecode_hash, self)


@internal
@pure
def _compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via `deployer`. Any change in the `bytecode_hash`
         or `salt` values will result in a new destination address.
    @param salt The 32-bytes random value used to create the contract address.
    @param bytecode_hash The 32-bytes bytecode digest of the contract creation bytecode.
    @param deployer The 20-bytes deployer address.
    """
    data: bytes32 = keccak256(concat(convert(_COLLISION_OFFSET, bytes32), convert(deployer, bytes32), salt, bytecode_hash))
    return convert(data, address)
