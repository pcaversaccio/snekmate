# pragma version ~=0.4.1
"""
@title Utility Functions to Access Historical Block Hashes
@custom:contract-name block_hash
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to access historical block hashes
        beyond the standard 256-block limit. We use the EIP-2935
        (https://eips.ethereum.org/EIPS/eip-2935) history contract,
        which maintains a ring buffer of the last 8,191 block hashes
        stored in state. For blocks within the last 256 blocks, we
        use the native `BLOCKHASH` opcode. For blocks between 257 and
        8,191 blocks ago, the function `_block_hash` queries via the
        specified `get` (https://eips.ethereum.org/EIPS/eip-2935#get)
        method the EIP-2935 history contract. For blocks older than 8,191
        or future blocks, we return zero, matching the `BLOCKHASH` behaviour.

        Please note that after EIP-2935 is activated, it takes 8,191 blocks
        to fully populate the history. Before that, only block hashes from
        the fork block onward are available.
"""


# @dev The `HISTORY_STORAGE_ADDRESS` contract address.
# @notice See the EIP-2935 specifications here: https://eips.ethereum.org/EIPS/eip-2935#specification.
_HISTORY_STORAGE_ADDRESS: constant(address) = 0x0000F90827F1C53a10cb7A02335B175320002935


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
    @notice For blocks older than 8,191 or future blocks, returns
            zero, matching the `BLOCKHASH` behaviour.
    @param block_number The 32-byte block number.
    @return bytes32 The 32-byte block hash for block number `block_number`.
    """
    # TBD: Should we allow for overflow behaviour here?
    distance: uint256 = unsafe_sub(block.number, block_number)
    return (
        self._history_storage_call(block_number) if (distance > 256 and distance <= 8191) else blockhash(block_number)
    )


@internal
@view
def _history_storage_call(block_number: uint256) -> bytes32:
    """
    @dev Returns the block hash for block number `block_number` by
         calling the `HISTORY_STORAGE_ADDRESS` contract address.
    @notice Please note that for any request outside the range of
            `[block.number - 8191, block.number - 1], this function
            reverts.
    @param block_number The 32-byte block number.
    @return bytes32 The 32-byte block hash for block number `block_number`.
    """
    return convert(
        raw_call(
            _HISTORY_STORAGE_ADDRESS,
            # Due to Vyper commit `5825e12` (https://github.com/vyperlang/vyper/commit/5825e127350ff1cc5647c23dfd7e31f32f1eaea8),
            # direct conversion from primitive types (like `bytes32`) to dynamic
            # `Bytes` is no longer supported. # As a workaround, we use `concat`
            # to construct the calldata until the issue is resolved:
            # https://github.com/vyperlang/vyper/issues/3349
            concat(convert(block_number, bytes32), b""),
            max_outsize=32,
            is_static_call=True,
        ),
        bytes32,
    )
