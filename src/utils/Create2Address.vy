# @version ^0.3.7
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


# @dev A Vyper contract cannot call directly between two external functions.
# To bypass this, we can use an interface.
interface ComputeCreate2Address:
    def compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address: pure


@external
@view
def compute_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE2` opcode.
         Any change in the `bytecode_hash` or `salt` values will
         result in a new destination address.
    @param salt The 32-byte random value used to create the contract address.
    @param bytecode_hash The 32-byte bytecode digest of the contract creation bytecode.
    @return address The 20-byte address where a contract will be stored.
    """
    return ComputeCreate2Address(self).compute_address(salt, bytecode_hash, self)


@external
@pure
def compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via `deployer` using the `CREATE2` opcode.
         Any change in the `bytecode_hash` or `salt` values will
         result in a new destination address.
    @param salt The 32-byte random value used to create the contract address.
    @param bytecode_hash The 32-byte bytecode digest of the contract creation bytecode.
    @param deployer The 20-byte deployer address.
    @return address The 20-byte address where a contract will be stored.
    """
    data: bytes32 = keccak256(concat(_COLLISION_OFFSET, convert(deployer, bytes20), salt, bytecode_hash))
    return self._convert_keccak256_2_address(data)


@internal
@pure
def _convert_keccak256_2_address(digest: bytes32) -> address:
    """
    @dev Converts a 32-byte keccak256 digest to an address.
    @param digest The 32-byte keccak256 digest.
    @return address The converted 20-byte address.
    """
    return convert(convert(digest, uint256) & max_value(uint160), address)
