# @version ^0.3.4
"""
@title `CREATE` EVM Opcode Utility Function for Address Calculation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice This function can be used to compute in advance the address
        where a smart contract will be deployed if deployed via the
        `CREATE` opcode. The implementation is inspired by my
        implementation here:
        https://github.com/pcaversaccio/create-util/blob/main/contracts/Create.sol.
"""


@internal
@pure
def _compute_address_rlp_self(nonce: uint256) -> address:
    """
    @dev Returns the address where a contract will be stored if
         deployed via this contract using the `CREATE` opcode.
    @param nonce The next uint256 nonce of this contract.
    """
    return self._compute_address_rlp(self, nonce)


@internal
@pure
def _compute_address_rlp(deployer: address, nonce: uint256) -> address:
    """
    @dev Returns the address where a contract will be stored
         if deployed via the `CREATE` opcode. For the specification
         of the Recursive Length Prefix (RLP) encoding scheme, please
         refer to p. 19 of the Ethereum Yellow Paper (https://ethereum.github.io/yellowpaper/paper.pdf)
         and the Ethereum Wiki (https://eth.wiki/fundamentals/rlp).
         For further insights also, see the following issue:
         https://github.com/transmissions11/solmate/issues/207.
         
         Based on the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md)
         specification, all contract accounts on the Ethereum mainnet
         are initiated with `nonce = 1`. Thus, the first contract address
         created by another contract is calculated with a non-zero nonce.
    @param deployer The 20-bytes deployer address.
    @param nonce The next uint256 nonce of the deployer address.
    """

    length: bytes1 = 0x94

    if (nonce == convert(0x00, uint256)):
        return self._convert_keccak256_2_address(keccak256(concat(convert(0xd6, bytes32), convert(length, bytes32), convert(deployer, bytes32), convert(0x80, bytes32))))
    elif (nonce <= convert(0x7f, uint256)):
        return self._convert_keccak256_2_address(keccak256(concat(convert(0xd6, bytes32), convert(length, bytes32), convert(deployer, bytes32), convert(nonce, bytes32))))
    elif (nonce <= convert(max_value(uint8), uint256)):
        return self._convert_keccak256_2_address(keccak256(concat(convert(0xd7, bytes32), convert(length, bytes32), convert(deployer, bytes32), convert(0x81, bytes32), convert(nonce, bytes32))))
    elif (nonce <= convert(max_value(uint16), uint256)):
        return self._convert_keccak256_2_address(keccak256(concat(convert(0xd8, bytes32), convert(length, bytes32), convert(deployer, bytes32), convert(0x82, bytes32), convert(nonce, bytes32))))
    elif (nonce <= convert(max_value(uint24), uint256)):
        return self._convert_keccak256_2_address(keccak256(concat(convert(0xd9, bytes32), convert(length, bytes32), convert(deployer, bytes32), convert(0x83, bytes32), convert(nonce, bytes32))))
    else:
    # @dev In the case of `nonce > convert(max_value(uint24), uint256)`,
    # we have the following encoding scheme:
    # 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ address ++ 0x84 ++ nonce)
    # 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
    # 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
        return self._convert_keccak256_2_address(keccak256(concat(convert(0xda, bytes32), convert(length, bytes32), convert(deployer, bytes32), convert(0x84, bytes32), convert(nonce, bytes32))))


@internal
@pure
def _convert_keccak256_2_address(digest: bytes32) -> address:
    """
    @dev Converts a 32-bytes keccak256 digest to an address.
    @param digest The 32-bytes keccak256 digest.
    """
    return convert(convert(digest, uint256) & max_value(uint160), address)
