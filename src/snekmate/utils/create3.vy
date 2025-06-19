# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `CREATE3`-Based Utility Functions
@custom:contract-name create3
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used either to deploy a contract via the
        `CREATE3` pattern (i.e. without an initcode factor) or to compute
        the address where a contract will be deployed using `CREATE3`.
        The implementation is inspired by Solmate's implementation here:
        https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol.
"""


# @dev We import the `create` module.
# @notice Please note that the `create` module
# is stateless and therefore does not require
# the `uses` keyword for usage.
from . import create


# @dev We import the `create2` module.
# @notice Please note that the `create2` module
# is stateless and therefore does not require
# the `uses` keyword for usage.
from . import create2


# @dev The proxy contract creation code.
#  -------------------------------------------------------------------+
#  Opcode      | Mnemonic         | Stack        | Memory             |
#  -------------------------------------------------------------------|
#  36          | CALLDATASIZE     | cds          |                    |
#  3d          | RETURNDATASIZE   | 0 cds        |                    |
#  3d          | RETURNDATASIZE   | 0 0 cds      |                    |
#  37          | CALLDATACOPY     |              | [0..cds): calldata |
#  36          | CALLDATASIZE     | cds          | [0..cds): calldata |
#  3d          | RETURNDATASIZE   | 0 cds        | [0..cds): calldata |
#  34          | CALLVALUE        | value 0 cds  | [0..cds): calldata |
#  f0          | CREATE           | newContract  | [0..cds): calldata |
#  -------------------------------------------------------------------|
#  Opcode      | Mnemonic         | Stack        | Memory             |
#  -------------------------------------------------------------------|
#  67 bytecode | PUSH8 bytecode   | bytecode     |                    |
#  3d          | RETURNDATASIZE   | 0 bytecode   |                    |
#  52          | MSTORE           |              | [0..8): bytecode   |
#  60 0x08     | PUSH1 0x08       | 0x08         | [0..8): bytecode   |
#  60 0x18     | PUSH1 0x18       | 0x18 0x08    | [0..8): bytecode   |
#  f3          | RETURN           |              | [0..8): bytecode   |
#  -------------------------------------------------------------------+
_PROXY_INIT_CODE: constant(Bytes[16]) = x"67363d3d37363d34f03d5260086018f3"


# @dev The `keccak256` hash of `_PROXY_INIT_CODE`.
_PROXY_INIT_CODE_HASH: constant(bytes32) = keccak256(_PROXY_INIT_CODE)


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
def _deploy_create3(salt: bytes32, init_code: Bytes[8_192]) -> address:
    """
    @dev Deploys a new contract via employing the `CREATE3` pattern
         (i.e. without an initcode factor) and using the salt value
         `salt`, the creation bytecode `init_code`, and `msg.value`
         as inputs.
    @notice Please note that the `init_code` represents the complete
            contract creation code, i.e. including the ABI-encoded
            constructor arguments, and if `msg.value` is non-zero,
            `init_code` must have a `payable` constructor. To align
            with other `CREATE3`-based implementations, we enforce via
            `is_contract` that the deployed contract contains non-empty
            bytecode.
    @param salt The 32-byte random value used to create the proxy
           contract address.
    @param init_code The maximum 8,192-byte contract creation bytecode.
    @return address The 20-byte address where the contract was deployed.
    """
    proxy: address = raw_create(_PROXY_INIT_CODE, salt=salt)
    raw_call(proxy, init_code, value=msg.value)
    new_contract: address = self._compute_create3_address_self(salt)
    assert new_contract.is_contract, "create3: contract creation failed"
    return new_contract


@internal
@view
def _compute_create3_address_self(salt: bytes32) -> address:
    """
    @dev Returns the address where a contract will be stored if deployed
         via this contract using the `CREATE3` pattern (i.e. without an
         initcode factor). Any change in the `salt` value will result in
         a new destination address.
    @param salt The 32-byte random value used to create the proxy contract
           address.
    @return address The 20-byte address where a contract will be stored.
    """
    return self._compute_create3_address(salt, self)


@internal
@pure
def _compute_create3_address(salt: bytes32, deployer: address) -> address:
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
    proxy: address = create2._compute_create2_address(salt, _PROXY_INIT_CODE_HASH, deployer)
    # Due to the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md)
    # specification, all contract accounts are initiated with `nonce = 1`.
    # Thus, the first contract address created by the proxy contract is
    # calculated with a non-zero nonce.
    return create._compute_create_address(proxy, 1)
