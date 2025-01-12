# pragma version ~=0.4.1b5
"""
@title `batch_distributor` Module Reference Implementation
@custom:contract-name batch_distributor_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and initialise the `batch_distributor` module.
from .. import batch_distributor as bd
initializes: bd


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    bd.__init__()


@external
@payable
def distribute_ether(data: bd.Batch):
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
    bd._distribute_ether(data)


@external
def distribute_token(token: bd.IERC20, data: bd.Batch):
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
    """
    bd._distribute_token(token, data)
