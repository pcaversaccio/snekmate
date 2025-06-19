# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `CREATE` EVM Opcode Utility Functions
@custom:contract-name create
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used either to deploy a contract via the
        `CREATE` opcode or to compute the address where a contract will
        be deployed using `CREATE`. The implementation is inspired by my
        implementation here:
        https://github.com/pcaversaccio/create-util/blob/main/contracts/Create.sol.
"""


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
def _deploy_create(init_code: Bytes[8_192]) -> address:
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
    return raw_create(init_code, value=msg.value)


@internal
@view
def _compute_create_address_self(nonce: uint256) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE` opcode.
    @param nonce The 32-byte account nonce of this contract.
    @return address The 20-byte address where a contract will be stored.
    """
    return self._compute_create_address(self, nonce)


@internal
@pure
def _compute_create_address(deployer: address, nonce: uint256) -> address:
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
    length: bytes1 = 0x94

    # The theoretical allowed limit, based on EIP-2681, for an
    # account nonce is 2**64-2: https://eips.ethereum.org/EIPS/eip-2681.
    assert nonce < convert(max_value(uint64), uint256), "create: invalid nonce value"

    # The integer zero is treated as an empty byte string and
    # therefore has only one length prefix, 0x80, which is
    # calculated via 0x80 + 0.
    if nonce == convert(0x00, uint256):
        return self._convert_keccak256_to_address(keccak256(concat(0xd6, length, convert(deployer, bytes20), 0x80)))
    # A one-byte integer in the [0x00, 0x7f] range uses its own
    # value as a length prefix, there is no additional "0x80 + length"
    # prefix that precedes it.
    elif nonce <= convert(0x7f, uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xd6, length, convert(deployer, bytes20), convert(convert(nonce, uint8), bytes1)))
        )
    # In the case of `nonce > convert(0x7f, uint256)` and
    # `nonce <= convert(max_value((uint8), uint256)`, we have the
    # following encoding scheme (the same calculation can be carried
    # over for higher nonce bytes):
    # 0xda = 0xc0 (short RLP prefix) + 0x1a (= the bytes length of: 0x94 + address + 0x84 + nonce, in hex),
    # 0x94 = 0x80 + 0x14 (= the bytes length of an address, 20 bytes, in hex),
    # 0x84 = 0x80 + 0x04 (= the bytes length of the nonce, 4 bytes, in hex).
    elif nonce <= convert(max_value(uint8), uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xd7, length, convert(deployer, bytes20), 0x81, convert(convert(nonce, uint8), bytes1)))
        )
    elif nonce <= convert(max_value(uint16), uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xd8, length, convert(deployer, bytes20), 0x82, convert(convert(nonce, uint16), bytes2)))
        )
    elif nonce <= convert(max_value(uint24), uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xd9, length, convert(deployer, bytes20), 0x83, convert(convert(nonce, uint24), bytes3)))
        )
    elif nonce <= convert(max_value(uint32), uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xda, length, convert(deployer, bytes20), 0x84, convert(convert(nonce, uint32), bytes4)))
        )
    elif nonce <= convert(max_value(uint40), uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xdb, length, convert(deployer, bytes20), 0x85, convert(convert(nonce, uint40), bytes5)))
        )
    elif nonce <= convert(max_value(uint48), uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xdc, length, convert(deployer, bytes20), 0x86, convert(convert(nonce, uint48), bytes6)))
        )
    elif nonce <= convert(max_value(uint56), uint256):
        return self._convert_keccak256_to_address(
            keccak256(concat(0xdd, length, convert(deployer, bytes20), 0x87, convert(convert(nonce, uint56), bytes7)))
        )

    return self._convert_keccak256_to_address(
        keccak256(concat(0xde, length, convert(deployer, bytes20), 0x88, convert(convert(nonce, uint64), bytes8)))
    )


@internal
@pure
def _convert_keccak256_to_address(digest: bytes32) -> address:
    """
    @dev Converts a 32-byte `keccak256` digest to an address.
    @param digest The 32-byte `keccak256` digest.
    @return address The converted 20-byte address.
    """
    return convert(convert(digest, uint256) & convert(max_value(uint160), uint256), address)
