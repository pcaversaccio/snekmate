# @version ^0.3.7
"""
@title Batch Sending Both Native and ERC-20 Tokens
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


from vyper.interfaces import ERC20


# @dev Transaction struct for the transaction payload.
struct Transaction:
    recipient: address
    amount: uint256


# @dev Batch struct for the array of transactions.
struct Batch:
     txns: DynArray[Transaction, max_value(uint8)]


@external
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value` in the
         creation-time EVM bytecode, the constructor is declared as `payable`.
    """
    pass


@external
@payable
@nonreentrant("lock")
def distribute_ether(data: DynArray[Batch, max_value(uint8)]):
    """
    @dev TBD
    @notice TBD
    @param data TBD
    """
    return_data: Bytes[32] = b""
    idx: uint256 = 0
    for batch in data:
        return_data = raw_call(batch.txns[idx].recipient, b"", max_outsize=32, value=batch.txns[idx].amount)
        idx += 1

    if (self.balance != 0):
        return_data = raw_call(msg.sender, b"", max_outsize=32, value=self.balance)


@external
def distribute_token(token: ERC20, data: DynArray[Batch, max_value(uint8)]):
    """
    @dev TBD
    @notice TBD
    @param token TBD
    @param data TBD
    """
    total: uint256 = 0
    inc: uint256 = 0
    for batch in data:
        total += batch.txns[inc].amount
        inc += 1

    # TODO: implement safeTransferFrom function
    token.transferFrom(msg.sender, self, total)
    
    idx: uint256 = 0
    for batch in data:
        # TODO: implement safeTransfer function
        token.transfer(batch.txns[idx].recipient, batch.txns[idx].amount)
        idx += 1
