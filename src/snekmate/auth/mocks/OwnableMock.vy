# pragma version ~=0.4.0b5
"""
@title Ownable Module Reference Implementation
@custom:contract-name OwnableMock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and initialise the `Ownable` module.
from .. import Ownable as ow
initializes: ow


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `Ownable` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: (
    ow.owner,
    ow.transfer_ownership,
    ow.renounce_ownership,
)


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice The `owner` role will be assigned to
            the `msg.sender`.
    """
    # The following line assigns the `owner`
    # to the `msg.sender`.
    ow.__init__()
