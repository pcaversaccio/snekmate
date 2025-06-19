# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Batch Sending Both Native and ERC-20 Tokens
@custom:contract-name batch_distributor
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used for batch sending
        both native and ERC-20 tokens. The implementation
        is inspired by my implementation here:
        https://github.com/pcaversaccio/batch-distributor/blob/main/contracts/BatchDistributor.sol,
        as well as by the original implementation of banteg:
        https://github.com/banteg/disperse-research.
"""


# @dev We import the `IERC20` interface, which is a
# built-in interface of the Vyper compiler.
from ethereum.ercs import IERC20


# @dev Transaction struct for the transaction payload.
struct Transaction:
    recipient: address
    amount: uint256


# @dev Batch struct for the array of transactions.
struct Batch:
     txns: DynArray[Transaction, max_value(uint8)]


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
@nonreentrant
def _distribute_ether(data: Batch):
    """
    @dev Distributes ether, denominated in wei, to a
         predefined batch of recipient addresses.
    @notice In the event that excessive ether is sent,
            the residual amount is returned back to the
            `msg.sender`. Please note that you must add the
            `payable` decorator to any `external` function
            that calls the `internal` function `_distribute_ether`
            to enable the handling of ether.

            Furthermore, it is important to note that an
            external call via `raw_call` does not perform
            an external code size check on the target address.
    @param data Nested struct object that contains an array
           of tuples that contain each a recipient address &
           ether amount in wei.
    """
    for txn: Transaction in data.txns:
        # A low-level call is used to guarantee compatibility
        # with smart contract wallets. As a general pre-emptive
        # safety measure, a reentrancy guard is used.
        raw_call(txn.recipient, b"", value=txn.amount)

    if self.balance != empty(uint256):
        # IMPORTANT: Any wei amount previously forced into this
        # contract (e.g. by using the `SELFDESTRUCT` opcode) will
        # be part of the refund transaction.
        raw_call(msg.sender, b"", value=self.balance)


@internal
@nonreentrant
def _distribute_token(token: IERC20, data: Batch):
    """
    @dev Distributes ERC-20 tokens, denominated in their corresponding
         lowest unit, to a predefined batch of recipient addresses.
    @notice To deal with (potentially) non-compliant ERC-20 tokens that do have
            no return value, we use the kwarg `default_return_value` for external
            calls. This function was introduced in Vyper version `0.3.4`. For more
            details see:
            - https://github.com/vyperlang/vyper/pull/2839,
            - https://github.com/vyperlang/vyper/issues/2812,
            - https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca.
            Note: Since we cast the token address into the official ERC-20 interface,
            the use of non-compliant ERC-20 tokens is prevented by design. Nevertheless,
            we keep this guardrail for security reasons.
    @param token The ERC-20 compatible (i.e. ERC-777 is also
           viable) token contract address.
    @param data Nested struct object that contains an array
           of tuples that contain each a recipient address &
           token amount.
    @custom:security To prevent a potential cross-function reentrancy via
                     `_distribute_ether`, as pre-emptive safety measure,
                     a reentrancy guard is used.
    """
    total: uint256 = empty(uint256)
    for txn: Transaction in data.txns:
        total += txn.amount

    # It is important to note that an external call via interface casting
    # always performs an external code size check on the target address unless
    # you add the kwarg `skip_contract_check=True`. If the check fails (i.e.
    # the target address is an EOA), the call reverts.
    assert extcall token.transferFrom(
        msg.sender, self, total, default_return_value=True
    ), "batch_distributor: transferFrom operation did not succeed"

    for txn: Transaction in data.txns:
        assert extcall token.transfer(
            txn.recipient, txn.amount, default_return_value=True
        ), "batch_distributor: transfer operation did not succeed"
