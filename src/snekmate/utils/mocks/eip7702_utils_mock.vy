# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `eip7702_utils` Module Reference Implementation
@custom:contract-name eip7702_utils_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `eip7702_utils` module.
# @notice Please note that the `eip7702_utils` module
# is stateless and therefore does not require the
# `initializes` keyword for initialisation.
from .. import eip7702_utils as eu


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@external
@view
def fetch_delegate(account: address) -> address:
    """
    @dev Returns the current EIP-7702 delegation contract
         for `account` if one has been set via a set code
         transaction, or the zero address `empty(address)`
         otherwise.
    @notice Note that an `account` can revoke its delegation
            at any time by setting the delegation contract to
            the zero address `empty(address)` via a set code
            transaction. However, this does not delete the
            `account`'s storage, which remains intact.
    @param account The 20-byte account address.
    @return address The 20-byte delegation contract address.
    """
    return eu._fetch_delegate(account)
