# pragma version ~=0.4.0b5
"""
@title Ownable2Step Module Reference Implementation
@custom:contract-name Ownable2StepMock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and initialise the `Ownable` module.
from .. import Ownable as ow
initializes: ow


# @dev We import and initialise the `Ownable2Step` module.
from .. import Ownable2Step as o2
initializes: o2[ownable := ow]


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `Ownable2Step` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: (
    o2.owner,
    o2.pending_owner,
    o2.transfer_ownership,
    o2.accept_ownership,
    o2.renounce_ownership,
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
    o2.__init__()
