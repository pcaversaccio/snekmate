# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Pausable Functions
@custom:contract-name pausable
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to implement an emergency stop
        mechanism that can be triggered by an authorised account.
        Please note that this contract does not include an access
        control mechanism (e.g., `ownable`) for triggering the emergency
        stop. Such functionality must be implemented by the importing
        contract, for instance (to avoid any NatSpec parsing error,
        no `@` character is added to the visibility decorator `@external`
        in the following example; please add them accordingly):
        ```vy
        from snekmate.auth import ownable
        initializes: ownable

        from snekmate.utils import pausable
        initializes: pausable

        exports: ...

        ...

        external
        def pause():
            ownable._check_owner()
            pausable._pause()

        external
        def unpause():
            ownable._check_owner()
            pausable._unpause()
        ```

        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Pausable.sol.
"""


# @dev Returns whether the contract is paused or not.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
paused: public(bool)


# @dev Emitted when `account` initiated the pause.
event Paused:
    account: address


# @dev Emitted when `account` lifted the pause.
event Unpaused:
    account: address


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
def _pause():
    """
    @dev Triggers the pause state. Note that the contract
         must not be paused.
    @notice This is an `internal` function without access
            restriction.
    """
    self._require_not_paused()
    self.paused = True
    log Paused(account=msg.sender)


@internal
def _unpause():
    """
    @dev Lifts the pause state. Note that the contract
         must be paused.
    @notice This is an `internal` function without access
            restriction.
    """
    self._require_paused()
    self.paused = False
    log Unpaused(account=msg.sender)


@internal
def _require_not_paused():
    """
    @dev Throws if the contract is paused.
    """
    assert not self.paused, "pausable: contract is paused"


@internal
def _require_paused():
    """
    @dev Throws if the contract is not paused.
    """
    assert self.paused, "pausable: contract is not paused"
