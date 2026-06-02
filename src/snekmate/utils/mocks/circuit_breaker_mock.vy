# pragma version ~=0.5.0a2
# pragma nonreentrancy off
"""
@title `circuit_breaker` Module Reference Implementation
@custom:contract-name circuit_breaker_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@custom:coauthor KhomenkovDev
"""


# @dev We import and initialise the `circuit_breaker` module.
from .. import circuit_breaker as cb
initializes: cb


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) the `external` getter
# function `breaker_tripped` from the `circuit_breaker` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: cb.breaker_tripped


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    cb.__init__()


@external
def trip():
    """
    @dev Trips the circuit breaker. Note that the breaker
         must not already be tripped; the trip is irreversible.
    @notice This is an `external` function without access
            restriction.
    """
    cb._trip()
