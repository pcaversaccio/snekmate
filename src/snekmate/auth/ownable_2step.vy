# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title 2-Step Ownership Transfer Functions
@custom:contract-name ownable_2step
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to implement a basic access
        control mechanism, where there is an account (an owner)
        that can be granted exclusive access to specific functions.
        This extension to the {ownable} contract includes a two-step
        ownership transfer mechanism where the new owner must call
        `accept_ownership` to replace the old one. This can help
        avoid common mistakes, such as ownership transfers to incorrect
        accounts or to contracts that are unable to interact with
        the permission system. By default, the owner account will
        be the one that deploys the contract. This can later be
        changed with `transfer_ownership` and `accept_ownership`.
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol.
"""


# @dev We import and use the `ownable` module.
from . import ownable
uses: ownable


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) the `external` getter
# function `owner` from the `ownable` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: ownable.owner


# @dev Returns the address of the pending owner.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
pending_owner: public(address)


# @dev Emitted when the ownership transfer from
# `previous_owner` to `new_owner` is initiated.
event OwnershipTransferStarted:
    previous_owner: indexed(address)
    new_owner: indexed(address)


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice At initialisation time, the `owner` role will
            be assigned to the `msg.sender` since we `uses`
            the `ownable` module, which implements the
            aforementioned logic at contract creation time.
    """
    pass


@external
def transfer_ownership(new_owner: address):
    """
    @dev Starts the ownership transfer of the contract
         to a new account `new_owner`.
    @notice Note that this function can only be called by
            the current `owner`. Importantly, there is no
            security risk in assigning `new_owner` to the
            zero address, as the default value of `pending_owner`
            is already set to the zero address, and the zero
            address cannot invoke `accept_ownership`. In fact,
            this can serve as a method to cancel an ongoing
            ownership transfer. Eventually, the function
            replaces the pending transfer if there is one.
    @param new_owner The 20-byte address of the new owner.
    """
    ownable._check_owner()
    self.pending_owner = new_owner
    log OwnershipTransferStarted(previous_owner=ownable.owner, new_owner=new_owner)


@external
def accept_ownership():
    """
    @dev The new owner accepts the ownership transfer.
    @notice Note that this function can only be
            called by the current `pending_owner`.
    """
    assert self.pending_owner == msg.sender, "ownable_2step: caller is not the new owner"
    self._transfer_ownership(msg.sender)


@external
def renounce_ownership():
    """
    @dev Leaves the contract without an owner.
    @notice Renouncing ownership will leave the
            contract without an owner, thereby
            removing any functionality that is
            only available to the owner.
    """
    ownable._check_owner()
    self._transfer_ownership(empty(address))


@internal
def _transfer_ownership(new_owner: address):
    """
    @dev Transfers the ownership of the contract
         to a new account `new_owner` and deletes
         any pending owner.
    @notice This is an `internal` function without
            access restriction.
    @param new_owner The 20-byte address of the new owner.
    """
    self.pending_owner = empty(address)
    ownable._transfer_ownership(new_owner)
