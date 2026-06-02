# pragma version ~=0.5.0a2
# pragma nonreentrancy off
"""
@title One-Way Circuit Breaker Functions
@custom:contract-name circuit_breaker
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@custom:coauthor KhomenkovDev
@notice These functions can be used to implement a one-way emergency
        shutdown mechanism. The breaker has exactly one state
        transition: from `False` (armed) to `True` (tripped). Once
        tripped, the breaker cannot be re-armed for the lifetime of
        the contract; this irreversibility is the entire feature of
        the module and distinguishes it from the reversible
        `pausable` module.
        Use `circuit_breaker` when a state change must be terminal
        by construction (e.g. permanent protocol shutdown, one-shot
        migration cut-over, mint cap hardening). The two modules are
        designed to be composed: `pausable` for routine, reversible
        circuit-breaking and `circuit_breaker` for the terminal step
        that must outlive any future governance action.
        Please note that this contract does not include an access
        control mechanism (e.g., `ownable`) for tripping the breaker.
        Such functionality must be implemented by the importing
        contract, for instance (to avoid any NatSpec parsing error,
        no `@` character is added to the visibility decorator `@external`
        in the following example; please add them accordingly):
        ```vy
        from snekmate.auth import ownable
        initializes: ownable

        from snekmate.utils import circuit_breaker as cb
        initializes: cb

        exports: cb.breaker_tripped

        ...

        external
        def trip():
            ownable._check_owner()
            cb._trip()
        ```

        The implementation is inspired by the one-way emergency stop
        pattern used across production DeFi protocols (e.g. MakerDAO's
        `End.cage()`, Compound v3 supply cap ratcheting, Aave's
        `EMERGENCY_ADMIN` permanent stop).
"""


# @dev Returns whether the circuit breaker has been tripped.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
breaker_tripped: public(bool)


# @dev Emitted when `account` trips the circuit breaker.
# Since the trip is irreversible, this event is emitted
# at most once per contract instance.
event BreakerTripped:
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
def _trip():
    """
    @dev Trips the circuit breaker. Note that the breaker
         must not already be tripped; the trip is irreversible.
    @notice This is an `internal` function without access
            restriction.
    """
    self._require_not_tripped()
    self.breaker_tripped = True
    log BreakerTripped(account=msg.sender)


@internal
def _require_not_tripped():
    """
    @dev Throws if the circuit breaker has been tripped.
    """
    assert not self.breaker_tripped, "circuit_breaker: breaker is tripped"
