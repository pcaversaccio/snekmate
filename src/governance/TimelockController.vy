# pragma version ^0.3.10
"""
@title Multi-Role-Based Timelock Controller Reference Implementation
@custom:contract-name TimelockController
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@custom:coauthor cairoeth
@notice This module allows for timelocking operations by scheduling and
        executing transactions. By leveraging AccessControl, the 
        TimelockController introduces three roles: proposer, executor,
        and canceller. The proposer role is responsible for proposing
        operations, the executor is responsible for executing scheduled
        proposals, and the canceller is responsible for cancelling
        proposals. The owner is the sole admin of the roles and can grant
        and revoke them. In the constructor, proposers will be granted
        the proposer and canceller roles.

        Proposals must be scheduled with a delay that is greater than or
        equal to the minimum delay (`minDelay()`), which can be updated via
        a proposal to itself and is measured in seconds. Additionally,
        proposals can be associated with preceding proposals, which must be
        executed before the proposal can be executed. Ready proposals can be
        executed by the executor, who is solely responsible for calling the
        `execute()` function.
        
        Proposals can be timelocked individually or in batches. The latter is
        useful for operations that require execution in the same block.

        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `IAccessControl`
# interface, which is written using standard Vyper
# syntax.
from ..auth.interfaces import IAccessControl
implements: IAccessControl


# @dev The default 32-byte admin role.
DEFAULT_ADMIN_ROLE: public(constant(bytes32)) = empty(bytes32)


# @dev The 32-byte proposer role.
# @notice Responsible for proposing operations.
PROPOSER_ROLE: public(constant(bytes32)) = keccak256("PROPOSER_ROLE")


# @dev The 32-byte executor role.
# @notice Responsible for executing scheduled proposals.
EXECUTOR_ROLE: public(constant(bytes32)) = keccak256("EXECUTOR_ROLE")


# @dev The 32-byte canceller role.
# @notice Responsible for cancelling proposals.
CANCELLER_ROLE: public(constant(bytes32)) = keccak256("CANCELLER_ROLE")


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0x7965DB0B, # The ERC-165 identifier for `IAccessControl`.
]


# @dev The 32-byte timestamp that specifies whether a
# proposal has been executed.
_DONE_TIMESTAMP: constant(uint256) = 1


# @dev The possible states of a proposal.
# @notice Enums are treated differently in Vyper and Solidity.
# The members are represented by `uint256` values (in Solidity
# the values are of type `uint8`) in the form `2**n`, where `n`
# is the index of the member in the range `0 <= n <= 255` (i.e.
# the first index value is 1). For further insights also, see
# the following Twitter thread:
# https://twitter.com/pcaversaccio/status/1626514029094047747.
enum OperationState:
    UNSET
    WAITING
    READY
    DONE


# @dev Returns the timestamp at which an operation becomes
# ready (`0` for `UNSET` operations, `1` for `DONE` operations).
get_timestamp: public(HashMap[bytes32, uint256])


# @dev Returns the minimum delay in seconds for an operation
# to become valid. This value can be changed by executing an
# operation that invokes `update_delay`.
get_minimum_delay: public(uint256)


# @dev Returns `True` if `account` has been granted `role`.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
hasRole: public(HashMap[bytes32, HashMap[address, bool]])


# @dev Returns the admin role that controls `role`.
getRoleAdmin: public(HashMap[bytes32, bytes32])


# @dev Emitted when a call is scheduled as part of
# operation `id`. Note that `index` is the index
# position of the proposal. If the proposal is
# individual, the `index` is `0`.
event CallScheduled:
    id: indexed(bytes32)
    index: indexed(uint256)
    target: address
    value: uint256
    data: Bytes[1_024]
    predecessor: bytes32
    delay: uint256


# @dev Emitted when a call is performed as part
# of operation `id`. Note that `index` is the
# index position of the proposal. If the proposal
# is individual, the `index` is `0`.
event CallExecuted:
    id: indexed(bytes32)
    index: indexed(uint256)
    target: address
    value: uint256
    data: Bytes[1_024]


# @dev Emitted when new proposal is scheduled with
# non-zero salt.
event CallSalt:
    id: indexed(bytes32)
    salt: bytes32


# @dev Emitted when operation `id` is cancelled.
event Cancelled:
    id: indexed(bytes32)


# @dev Emitted when the minimum delay for future
# operations is modified.
event MinimumDelayChange:
    old_duration: uint256
    new_duration: uint256


# @dev Emitted when `new_admin_role` is set as
# `role`'s admin role, replacing `previous_admin_role`.
# Note that `DEFAULT_ADMIN_ROLE` is the starting
# admin for all roles, despite `RoleAdminChanged`
# not being emitted signaling this.
event RoleAdminChanged:
    role: indexed(bytes32)
    previous_admin_role: indexed(bytes32)
    new_admin_role: indexed(bytes32)


# @dev Emitted when `account` is granted `role`.
# Note that `sender` is the account (an admin
# role bearer) that originated the contract call.
event RoleGranted:
    role: indexed(bytes32)
    account: indexed(address)
    sender: indexed(address)


# @dev Emitted when `account` is revoked `role`.
# Note that `sender` is the account that originated
# the contract call:
#   - if using `revokeRole`, it is the admin role
#     bearer,
#   - if using `renounceRole`, it is the role bearer
#     (i.e. `account`).
event RoleRevoked:
    role: indexed(bytes32)
    account: indexed(address)
    sender: indexed(address)


@external
@payable
def __init__(minimum_delay_: uint256, proposers_: DynArray[address, 128], executors_: DynArray[address, 128], admin_: address):
    """
    @dev Initialises the contract with the following parameters:
         - `minimum_delay_`: The initial minimum delay in seconds
            for operations,
         - `proposers_`: The accounts to be granted proposer and
            canceller roles,
         - `executors_`: The accounts to be granted executor role,
         - `admin_`: The optional account to be granted admin role
            (disable with the zero address).

         IMPORTANT: The optional admin can aid with initial
         configuration of roles after deployment without being
         subject to delay, but this role should be subsequently
         renounced in favor of administration through timelocked
         proposals.

         To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @param minimum_delay_ The 32-byte minimum delay in seconds
           for operations.
    @param proposers_ The 20-byte array of accounts to be granted
           proposer and canceller roles.
    @param executors_ The 20-byte array of accounts to be granted
           executor role.
    @param admin_ The 20-byte (optional) account to be granted admin
           role.
    """
    # Configure the contract to be self-administered.
    self._grant_role(DEFAULT_ADMIN_ROLE, self)

    # Set the optional admin.
    if (admin_ != empty(address)):
        self._grant_role(DEFAULT_ADMIN_ROLE, admin_)

    # Register the proposers and cancellers.
    for proposer in proposers_:
        self._grant_role(PROPOSER_ROLE, proposer)
        self._grant_role(CANCELLER_ROLE, proposer)

    # Register the executors.
    for executor in executors_:
        self._grant_role(EXECUTOR_ROLE, executor)

    # Set the minimum delay.
    self.get_minimum_delay = minimum_delay_
    log MinimumDelayChange(empty(uint256), minimum_delay_)


@external
@payable
def __default__():
    """
    @dev Contract might receive/hold ETH as part of the
         maintenance process.
    """
    pass


@external
@view
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interface_id`.
    @param interface_id The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return interface_id in _SUPPORTED_INTERFACES


@external
@view
def is_operation(id: bytes32) -> bool:
    """
    @dev Returns whether an `id` corresponds to a registered
         operation. This includes both `WAITING`, `READY`, and
         `DONE` operations.
    @param id The 32-byte operation identifier.
    @return bool The verification whether the `id`
            corresponds to a registered operation or not.
    """
    return self._is_operation(id)


@external
@view
def is_operation_pending(id: bytes32) -> bool:
    """
    @dev Returns whether an operation is pending or not.
         Note that a "pending" operation may also be
         "ready".
    @param id The 32-byte operation identifier.
    @return bool The verification whether the operation
            is pending or not.
    """
    return self._is_operation_pending(id)


@external
@view
def is_operation_ready(id: bytes32) -> bool:
    """
    @dev Returns whether an operation is ready for
         execution. Note that a "ready" operation is
         also "pending".
    @param id The 32-byte operation identifier.
    @return bool The verification whether the operation
            is ready or not.
    """
    return self._is_operation_ready(id)


@external
@view
def is_operation_done(id: bytes32) -> bool:
    """
    @dev Returns whether an operation is done or not.
    @param id The 32-byte operation identifier.
    @return bool The verification whether the operation
            is done or not.
    """
    return self._is_operation_done(id)


@external
@view
def get_operation_state(id: bytes32) -> OperationState:
    """
    @dev Returns the state of an operation.
    @param id The 32-byte operation identifier.
    @return OperationState The 32-byte state of the
            operation.
    """
    return self._get_operation_state(id)


@external
@pure
def hash_operation(target: address, amount: uint256, data: Bytes[1_024], predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev Returns the identifier of an operation containing
         a single transaction.
    @param target The 20-bytes address of the target contract.
    @param amount The 32-byte amount of native token to transfer
           with the call.
    @param data The maximum 1,024-byte ABI-encoded calldata.
    @param predecessor The 32-byte hash of the preceding
           operation (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @return bytes32 The 32-byte hash of the operation.
    """
    return self._hash_operation(target, amount, data, predecessor, salt)


@external
@pure
def hash_operation_batch(targets: DynArray[address, 128], amounts: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128],\
                         predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev Returns the identifier of an operation containing
         a batch of transactions.
    @param targets The 20-byte address of the targets contract.
    @param amounts The 32-byte array of native token amounts to
           transfer with each call.
    @param data The maximum 1,024-byte array of ABI-encoded calldata.
    @param predecessor The 32-byte hash of the preceding
           operation (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @return bytes32 The 32-byte hash of the operation.
    """
    return self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)


@external
def schedule(target: address, amount: uint256, data: Bytes[1_024], predecessor: bytes32, salt: bytes32, delay: uint256):
    """
    @dev Schedule an operation containing a single transaction.
         Emits `CallSalt` if salt is non-zero and `CallScheduled`.
    @notice Requires the caller to have the `proposer` role.
    @param target The 20-byte address of the target contract.
    @param amount The 32-byte amount of native token to transfer
           with the call.
    @param data The maximum 1,024-byte ABI-encoded calldata.
    @param predecessor The hash of the preceding
           operation.
    @param salt The salt of the operation.
    @param delay The delay before the operation
           becomes valid. Must be greater than or
           equal to the minimum delay.
    """
    self._check_role(PROPOSER_ROLE, msg.sender)
    id: bytes32 = self._hash_operation(target, amount, data, predecessor, salt)
    self._schedule(id, delay)
    log CallScheduled(id, empty(uint256), target, amount, data, predecessor, delay)
    if (salt != empty(bytes32)):
        log CallSalt(id, salt)


@external
def schedule_batch(targets: DynArray[address, 128], amounts: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128],\
                  predecessor: bytes32, salt: bytes32, delay: uint256):
    """
    @dev Schedule an operation containing a batch
         of transactions. Emits `CallSalt` if salt
         is non-zero, and one `CallScheduled` event
         per transaction in the batch.
    @param targets The address of the target contracts.
    @param amounts The amounts of native token to send
           with the call.
    @param payloads The ABI-encoded calls data.
    @param predecessor The hash of the preceding
           operation.
    @param salt The salt of the operation.
    @param delay The delay before the operation
           becomes valid. Must be greater than or
           equal to the minimum delay.
    @notice Requires the caller to have the 
            `proposer` role.
    """
    self._check_role(PROPOSER_ROLE, msg.sender)
    assert len(targets) == len(amounts) and len(targets) == len(payloads), "TimelockController: invalid operation length"
    id: bytes32 = self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)
    self._schedule(id, delay)
    idx: uint256 = empty(uint256)
    for target in targets:
        log CallScheduled(id, idx, target, amounts[idx], payloads[idx], predecessor, delay)
        # The following line cannot overflow because we have
        # limited the dynamic array.
        idx = unsafe_add(idx, 1)
    if (salt != empty(bytes32)):
        log CallSalt(id, salt)


@external
def cancel(id: bytes32):
    """
    @dev Cancel an operation.
    @notice Requires the caller to have the 
            `canceller` role.
    @param id The 32-byte operation identifier.
    """
    self._check_role(CANCELLER_ROLE, msg.sender)
    assert self._is_operation_pending(id), "TimelockController: operation cannot be cancelled"
    self.get_timestamp[id] = empty(uint256)
    log Cancelled(id)


@external
@payable
def execute(target: address, amount: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32):
    """
    @dev Execute an (ready) operation
         containing a single transaction.
         Emits a `CallExecuted` event.
    @param target The address of the target contract.
    @param amount The amount of native token to send
           with the call.
    @param payload The ABI-encoded call data.
    @param predecessor The hash of the preceding
           operation.
    @param salt The salt of the operation.
    @notice Requires the caller to have the `executor` role.
            This function can reenter, but it doesn't pose
            a risk because `_afterCall` checks that the
            proposal is pending, thus any modifications to
            the operation during reentrancy should be caught.
    """
    self._only_role_or_open_role(EXECUTOR_ROLE)
    id: bytes32 = self._hash_operation(target, amount, payload, predecessor, salt)

    self._before_call(id, predecessor)
    self._execute(target, amount, payload)
    log CallExecuted(id, empty(uint256), target, amount, payload)
    self._after_call(id)


@external
@payable
def execute_batch(targets: DynArray[address, 128], amounts: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128],\
                  predecessor: bytes32, salt: bytes32):
    """
    @dev Execute an (ready) operation
         containing a batch of transactions.
         Emits one `CallExecuted` event per
         transaction in the batch.
    @param targets The address of the target contracts.
    @param amounts The amounts of native token to send
           with the call.
    @param payloads The ABI-encoded calls data.
    @param predecessor The hash of the preceding
           operation.
    @param salt The salt of the operation.
    @notice Requires the caller to have the `executor` role.
            This function can reenter, but it doesn't pose
            a risk because `_afterCall` checks that the
            proposal is pending, thus any modifications to
            the operation during reentrancy should be caught.
    """
    self._only_role_or_open_role(EXECUTOR_ROLE)
    assert len(targets) == len(amounts) and len(targets) == len(payloads), "TimelockController: invalid operation length"
    id: bytes32 = self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)

    self._before_call(id, predecessor)
    idx: uint256 = empty(uint256)
    for target in targets:
        self._execute(target, amounts[idx], payloads[idx])
        log CallExecuted(id, idx, target, amounts[idx], payloads[idx])
        # The following line cannot overflow because we have
        # limited the dynamic array.
        idx = unsafe_add(idx, 1)
    self._after_call(id)


@external
def update_delay(new_delay: uint256):
    """
    @dev Changes the minimum timelock duration for future
         operations. Emits a `MinDelayChange` event.
    @param newDelay The new minimum delay in seconds.
    @notice Requires the caller to be the timelock itself.
            This can only be achieved by scheduling and
            later executing an operation where the timelock
            is the target and the data is the ABI-encoded
            call to this function.
    """
    assert msg.sender == self, "TimelockController: unauthorised"
    log MinimumDelayChange(self.get_minimum_delay, new_delay)
    self.get_minimum_delay = new_delay


@external
def grantRole(role: bytes32, account: address):
    """
    @dev Grants `role` to `account`.
    @notice If `account` had not been already
            granted `role`, emits a `RoleGranted`
            event. Note that the caller must have
            `role`'s admin role.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._grant_role(role, account)


@external
def revokeRole(role: bytes32, account: address):
    """
    @dev Revokes `role` from `account`.
    @notice If `account` had been granted `role`,
            emits a `RoleRevoked` event. Note that
            the caller must have `role`'s admin role.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._revoke_role(role, account)


@external
def renounceRole(role: bytes32, account: address):
    """
    @dev Revokes `role` from the calling account.
    @notice Roles are often managed via `grantRole`
            and `revokeRole`. This function's purpose
            is to provide a mechanism for accounts to
            lose their privileges if they are compromised
            (such as when a trusted device is misplaced).
            If the calling account had been granted `role`,
            emits a `RoleRevoked` event. Note that the
            caller must be `account`.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    assert account == msg.sender, "AccessControl: can only renounce roles for itself"
    self._revoke_role(role, account)


@external
def set_role_admin(role: bytes32, admin_role: bytes32):
    """
    @dev Sets `admin_role` as `role`'s admin role.
    @notice Note that the caller must have `role`'s
            admin role.
    @param role The 32-byte role definition.
    @param admin_role The new 32-byte admin role definition.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._set_role_admin(role, admin_role)


@internal
@view
def _is_operation(id: bytes32) -> bool:
    """
    @dev Internal logic of `isOperation`.
    @param id The 32-byte operation identifier.
    @return bool The verification whether the id
            corresponds to a registered operation or not.
    """
    return self._get_operation_state(id) != OperationState.UNSET


@internal
def _only_role_or_open_role(role: bytes32):
    """
    @dev Used to limit a function to be callable only by
         a certain role. In addition to checking the 
         sender's role, `empty(address)` is also
         considered. Granting a role to `empty(address)`
         is equivalent to enabling this role for everyone.
    @param role The 32-byte role definition.
    """
    if (not(self.hasRole[role][empty(address)])):
        self._check_role(role, msg.sender)


@internal
@view
def _is_operation_pending(id: bytes32) -> bool:
    """
    @dev Internal logic of `isOperationPending`.
    @param id The 32-byte operation identifier.
    @return bool The verification whether the operation
            is pending or not.
    """
    state: OperationState = self._get_operation_state(id)
    return state == OperationState.WAITING or state == OperationState.READY


@internal
@view
def _is_operation_ready(id: bytes32) -> bool:
    """
    @dev Internal logic of `_isOperationReady`.
    @param id The 32-byte operation identifier.
    @return bool The verification whether
            the operation is ready or not.
    """
    return self._get_operation_state(id) == OperationState.READY


@internal
@view
def _is_operation_done(id: bytes32) -> bool:
    """
    @dev Internal logic of `_isOperationDone`.
    @param id The 32-byte operation identifier.
    @return bool The verification whether
            the operation is done or not.
    """
    return self._get_operation_state(id) == OperationState.DONE


@internal
@view
def _get_operation_state(id: bytes32) -> OperationState:
    """
    @dev Internal logic of `_getOperationState`.
    @param id The 32-byte operation identifier.
    @return OperationState The state of the
            operation.
    """
    timestamp: uint256 = self.get_timestamp[id]
    if (timestamp == empty(uint256)):
        return OperationState.UNSET
    elif (timestamp == _DONE_TIMESTAMP):
        return OperationState.DONE
    elif (timestamp > block.timestamp):
        return OperationState.WAITING
    else:
        return OperationState.READY


@internal
@pure
def _hash_operation(target: address, amount: uint256, data: Bytes[1_024], predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev Internal logic of `hashOperation`.
    @param target The address of the target contract.
    @param amount The amount of native token to send
           with the call.
    @param data The ABI-encoded call data.
    @param predecessor The hash of the preceding
           operation (optional with empty bytes).
    @param salt The salt of the operation.
    @return bytes32 The hash of the operation.
    """
    return keccak256(_abi_encode(target, amount, data, predecessor, salt))


@internal
@pure
def _hash_operation_batch(targets: DynArray[address, 128], amounts: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128],\
                          predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev An `internal` helper function that returns `hash_operationBatch`.
    @param targets The address of the targets contract.
    @param amounts The amounts of native token to send
           with each call.
    @param payloads The ABI-encoded calls data.
    @param predecessor The hash of the preceding
           operation (optional with empty bytes).
    @param salt The salt of the operation.
    @return bytes32 The hash of the operation.
    """
    return keccak256(_abi_encode(targets, amounts, payloads, predecessor, salt))


@internal
def _schedule(id: bytes32, delay: uint256):
    """
    @dev Schedules an operation that is to become valid
         after a given delay.
    @param id The 32-byte operation identifier.
    @param delay The 32-byte delay before the operation
           becomes valid. Must be greater than or equal
           to the minimum delay.
    """
    assert not(self._is_operation(id)), "TimelockController: operation already scheduled"
    assert delay >= self.get_minimum_delay, "TimelockController: insufficient delay"
    self.get_timestamp[id] = block.timestamp + delay


@internal
def _execute(target: address, amount: uint256, payload: Bytes[1_024]):
    """
    @dev Executes an operation's call.
    @param target The 20-byte address of the target contract.
    @param amount The 32-byte amount of native token to transfer
           with the call.
    @param data The maximum 1,024-byte array of ABI-encoded calldata.
    """
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    success, return_data = raw_call(target, payload, max_outsize=255, value=amount, revert_on_failure=False)
    if (not(success)):
        if len(return_data) != 0:
            raw_revert(return_data)
        else:
            raise "TimelockController: underlying transaction reverted"


@internal
@view
def _before_call(id: bytes32, predecessor: bytes32):
    """
    @dev Checks before execution of an operation's calls.
    @param id The 32-byte operation identifier.
    @param predecessor The 32-byte hash of the preceding
           operation.
    """
    assert self._is_operation_ready(id), "TimelockController: operation is not ready"
    assert predecessor == empty(bytes32) or self._is_operation_done(predecessor), "TimelockController: predecessor operation is not done"


@internal
def _after_call(id: bytes32):
    """
    @dev Checks after execution of an operation's calls.
    @param id The 32-byte operation identifier.
    """
    assert self._is_operation_ready(id), "TimelockController: operation is not ready"
    self.get_timestamp[id] = _DONE_TIMESTAMP


@internal
def _check_role(role: bytes32, account: address):
    """
    @dev Sourced from {AccessControl-_check_role}.
    @notice See {AccessControl-_check_role} for the
            function docstring.
    """
    assert self.hasRole[role][account], "AccessControl: account is missing role"


@internal
def _set_role_admin(role: bytes32, admin_role: bytes32):
    """
    @dev Sourced from {AccessControl-_set_role_admin}.
    @notice See {AccessControl-_set_role_admin} for the
            function docstring.
    """
    previous_admin_role: bytes32 = self.getRoleAdmin[role]
    self.getRoleAdmin[role] = admin_role
    log RoleAdminChanged(role, previous_admin_role, admin_role)


@internal
def _grant_role(role: bytes32, account: address):
    """
    @dev Sourced from {AccessControl-_grant_role}.
    @notice See {AccessControl-_grant_role} for the
            function docstring.
    """
    if (not(self.hasRole[role][account])):
        self.hasRole[role][account] = True
        log RoleGranted(role, account, msg.sender)


@internal
def _revoke_role(role: bytes32, account: address):
    """
    @dev Sourced from {AccessControl-_revoke_role}.
    @notice See {AccessControl-_revoke_role} for the
            function docstring.
    """
    if (self.hasRole[role][account]):
        self.hasRole[role][account] = False
        log RoleRevoked(role, account, msg.sender)
