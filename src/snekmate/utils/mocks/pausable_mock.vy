# pragma version ~=0.4.1rc2
"""
@title `pausable` Module Reference Implementation
@custom:contract-name pausable_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and initialise the `pausable` module.
from .. import pausable as ps
initializes: ps


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `pausable` module. The built-in dunder method
# `__interface__` allows you to export all functions of a
# module without specifying the individual functions (see
# https://github.com/vyperlang/vyper/pull/3919). Please take
# note that if you do not know the full interface of a module
# contract, you can get the `.vyi` interface in Vyper by using
# `vyper -f interface your_filename.vy` or the external interface
# by using `vyper -f external_interface your_filename.vy`.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: ps.__interface__


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    ps.__init__()


@external
def pause():
    """
    @dev Triggers the pause state. Note that the contract
         must not be paused.
    @notice This is an `external` function without access
            restriction.
    """
    ps._pause()


@external
def unpause():
    """
    @dev Lifts the pause state. Note that the contract
         must be paused.
    @notice This is an `external` function without access
            restriction.
    """
    ps._unpause()
