# @version ^0.3.4
"""
@title `CREATE2` EVM Opcode Utility Functions for Address Calculations
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions can be used to compute in advance the address
        where a smart contract will be deployed if deployed via the
        `CREATE2` opcode. The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol.
"""


_COLLISION_OFFSET: constant(bytes1) = 0xFF


@internal
@view
def _compute_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE2` opcode.
         Any change in the `bytecode_hash` or `salt` values will
         result in a new destination address.
    @param salt The 32-bytes random value used to create the contract address.
    @param bytecode_hash The 32-bytes bytecode digest of the contract creation bytecode.
    """
    return self._compute_address(salt, bytecode_hash, self)


@internal
@pure
def _compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE2` opcode.
         Any change in the `bytecode_hash` or `salt` values will
         result in a new destination address.
    @param salt The 32-bytes random value used to create the contract address.
    @param bytecode_hash The 32-bytes bytecode digest of the contract creation bytecode.
    @param deployer The 20-bytes deployer address.
    """
    data: bytes32 = keccak256(concat(_COLLISION_OFFSET, convert(deployer, bytes20), salt, bytecode_hash))
    return self._convert_keccak256_2_address(data)


@internal
@pure
def _convert_keccak256_2_address(digest: bytes32) -> address:
    """
    @dev Converts a 32-bytes keccak256 digest to an address.
    @param digest The 32-bytes keccak256 digest.
    """
    return convert(convert(digest, uint256) & max_value(uint160), address)
