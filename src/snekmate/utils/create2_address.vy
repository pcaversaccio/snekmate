# pragma version ~=0.4.0
"""
@title `CREATE2` EVM Opcode Utility Functions for Address Calculations
@custom:contract-name create2_address
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to compute in advance the address
        where a smart contract will be deployed if deployed via the
        `CREATE2` opcode. The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol.
"""


# @dev The 1-byte `CREATE2` offset constant used to prevent
# collisions with addresses created using the traditional
# `keccak256(rlp([sender, nonce]))` formula.
_COLLISION_OFFSET: constant(bytes1) = 0xFF


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@internal
@view
def _compute_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
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
    return self._compute_address(salt, bytecode_hash, self)


@internal
@pure
def _compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
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
    return convert(convert(digest, uint256) & convert(max_value(uint160), uint256), address)
