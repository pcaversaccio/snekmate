# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Utility Functions to Access Historical Block Hashes
@custom:contract-name block_hash
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to access the historical block
        hashes beyond the default 256-block limit. We use the EIP-2935
        (https://eips.ethereum.org/EIPS/eip-2935) history contract,
        which maintains a ring buffer of the last 8,191 block hashes
        stored in state. For the blocks within the last 256 blocks,
        we use the native `BLOCKHASH` opcode. For blocks between 257
        and 8,191 blocks ago, the function `_block_hash` queries via
        the specified `get` (https://eips.ethereum.org/EIPS/eip-2935#get)
        method the EIP-2935 history contract. For blocks older than
        8,191 or future blocks (including the current one), we return
        zero, matching the `BLOCKHASH` behaviour.

        Please note that after EIP-2935 is activated, it takes 8,191
        blocks to fully populate the history. Before that, only block
        hashes from the fork block onward are available.
"""


# @dev The `HISTORY_STORAGE_ADDRESS` contract address.
# @notice See the EIP-2935 specifications here: https://eips.ethereum.org/EIPS/eip-2935#specification.
_HISTORY_STORAGE_ADDRESS: constant(address) = 0x0000F90827F1C53a10cb7A02335B175320002935


# @dev The `keccak256` hash of the runtime bytecode of the
# history contract deployed at `HISTORY_STORAGE_ADDRESS`.
_HISTORY_STORAGE_RUNTIME_BYTECODE_HASH: constant(bytes32) = (
    0x6e49e66782037c0555897870e29fa5e552daf4719552131a0abce779daec0a5d
)


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
def _block_hash(block_number: uint256) -> bytes32:
    """
    @dev Returns the block hash for block number `block_number`.
    @notice For blocks older than 8,191 or future blocks (including
            the current one), returns zero, matching the `BLOCKHASH`
            behaviour. Furthermore, this function does verify if the
            history contract is deployed. If the history contract is
            undeployed, the function will fallback to the `BLOCKHASH`
            behaviour.
    @param block_number The 32-byte block number.
    @return bytes32 The 32-byte block hash for block number `block_number`.
    """
    # For future blocks (including the current one), we already return
    # an empty `bytes32` value here in order not to iterate through the
    # remaining code.
    if block_number >= block.number:
        return empty(bytes32)

    delta: uint256 = unsafe_sub(block.number, block_number)

    if delta <= 256:
        return blockhash(block_number)
    elif delta > 8191 or _HISTORY_STORAGE_ADDRESS.codehash != _HISTORY_STORAGE_RUNTIME_BYTECODE_HASH:
        # The Vyper built-in function `blockhash` reverts if the block number
        # is more than `256` blocks behind the current block. We explicitly
        # handle this case (i.e. `delta > 8191`) to ensure the function returns
        # an empty `bytes32` value rather than reverting (i.e. exactly matching
        # the `BLOCKHASH` opcode behaviour).
        return empty(bytes32)
    else:
        return self._get_history_storage(block_number)


@internal
@view
def _get_history_storage(block_number: uint256) -> bytes32:
    """
    @dev Returns the block hash for block number `block_number` by
         calling the `HISTORY_STORAGE_ADDRESS` contract address.
    @notice Please note that for any request outside the range of
            `[block.number - 8191, block.number - 1]`, this function
            reverts (see https://eips.ethereum.org/EIPS/eip-2935#get).
            Furthermore, this function does not verify if the history
            contract is deployed. If the history contract is undeployed,
            the function will return an empty `bytes32` value.
    @param block_number The 32-byte block number.
    @return bytes32 The 32-byte block hash for block number `block_number`.
    """
    return convert(
        raw_call(
            _HISTORY_STORAGE_ADDRESS,
            abi_encode(block_number),
            max_outsize=32,
            is_static_call=True,
        ),
        bytes32,
    )
