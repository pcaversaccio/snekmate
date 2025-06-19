# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Owner-Based Access Control Functions
@custom:contract-name ownable
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to implement a basic access
        control mechanism, where there is an account (an owner)
        that can be granted exclusive access to specific functions.
        By default, the owner account will be the one that deploys
        the contract. This can later be changed with `transfer_ownership`.
        An exemplary integration can be found in the ERC-20 implementation here:
        https://github.com/pcaversaccio/snekmate/blob/main/src/snekmate/tokens/erc20.vy.
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol.
"""


# @dev Returns the address of the current owner.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
owner: public(address)


# @dev Emitted when the ownership is transferred
# from `previous_owner` to `new_owner`.
event OwnershipTransferred:
    previous_owner: indexed(address)
    new_owner: indexed(address)


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
    self._transfer_ownership(msg.sender)


@external
def transfer_ownership(new_owner: address):
    """
    @dev Transfers the ownership of the contract
         to a new account `new_owner`.
    @notice Note that this function can only be
            called by the current `owner`. Also,
            the `new_owner` cannot be the zero address.
    @param new_owner The 20-byte address of the new owner.
    """
    self._check_owner()
    assert new_owner != empty(address), "ownable: new owner is the zero address"
    self._transfer_ownership(new_owner)


@external
def renounce_ownership():
    """
    @dev Leaves the contract without an owner.
    @notice Renouncing ownership will leave the
            contract without an owner, thereby
            removing any functionality that is
            only available to the owner.
    """
    self._check_owner()
    self._transfer_ownership(empty(address))


@internal
def _check_owner():
    """
    @dev Throws if the sender is not the owner.
    """
    assert msg.sender == self.owner, "ownable: caller is not the owner"


@internal
def _transfer_ownership(new_owner: address):
    """
    @dev Transfers the ownership of the contract
         to a new account `new_owner`.
    @notice This is an `internal` function without
            access restriction.
    @param new_owner The 20-byte address of the new owner.
    """
    old_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(previous_owner=old_owner, new_owner=new_owner)
