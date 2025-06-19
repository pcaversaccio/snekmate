# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `CREATE2` EVM Opcode Utility Functions
@custom:contract-name create2
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used either to deploy a contract via the
        `CREATE2` opcode or to compute the address where a contract will
        be deployed using `CREATE2`. The implementation is inspired by
        OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol.
"""


# @dev We import the `create` module.
# @notice Please note that the `create` module
# is stateless and therefore does not require
# the `uses` keyword for usage.
from . import create


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
@payable
def _deploy_create2(salt: bytes32, init_code: Bytes[8_192]) -> address:
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
    return raw_create(init_code, value=msg.value, salt=salt)


@internal
@view
def _compute_create2_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
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
    return self._compute_create2_address(salt, bytecode_hash, self)


@internal
@pure
def _compute_create2_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
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
    digest: bytes32 = keccak256(concat(_COLLISION_OFFSET, convert(deployer, bytes20), salt, bytecode_hash))
    return create._convert_keccak256_to_address(digest)
