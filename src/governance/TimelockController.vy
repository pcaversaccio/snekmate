# pragma version ^0.3.10

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


# @dev An additional 32-byte access role.
# @notice Please adjust the naming of the variable
# according to your specific requirement,
# e.g. `MINTER_ROLE`.
ADDITIONAL_ROLE_1: public(constant(bytes32)) = keccak256("ADDITIONAL_ROLE_1")


# @dev An additional 32-byte access role.
# @notice Please adjust the naming of the variable
# according to your specific requirement,
# e.g. `PAUSER_ROLE`. Also, feel free to add more
# roles if necessary. In this case, it is important
# to extend the constructor accordingly.
ADDITIONAL_ROLE_2: public(constant(bytes32)) = keccak256("ADDITIONAL_ROLE_2")


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0x7965DB0B, # The ERC-165 identifier for `IAccessControl`.
]


# @dev Returns `True` if `account` has been granted `role`.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
hasRole: public(HashMap[bytes32, HashMap[address, bool]])


# @dev Returns the admin role that controls `role`.
getRoleAdmin: public(HashMap[bytes32, bytes32])


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

PROPOSER_ROLE: public(constant(bytes32)) = keccak256("PROPOSER_ROLE")

EXECUTOR_ROLE: public(constant(bytes32)) = keccak256("EXECUTOR_ROLE")

CANCELLER_ROLE: public(constant(bytes32)) = keccak256("CANCELLER_ROLE")

_DONE_TIMESTAMP: constant(uint256) = 1

_timestamps: HashMap[bytes32, uint256]

_minDelay: uint256

enum OperationState:
    Unset
    Waiting
    Ready
    Done

event CallScheduled:
    id: indexed(bytes32)
    index: indexed(uint256)
    target: address
    value: uint256
    data: Bytes[1_024]
    predecessor: bytes32
    delay: uint256

event CallExecuted:
    id: indexed(bytes32)
    index: indexed(uint256)
    target: address
    value: uint256
    data: Bytes[1_024]

event CallSalt:
    id: indexed(bytes32)
    salt: bytes32

event Cancelled:
    id: indexed(bytes32)

event MinDelayChange:
    oldDuration: uint256
    newDuration: uint256

@external
def __init__(minDelay: uint256, proposers: DynArray[address, 128], executors: DynArray[address, 128], admin: address):
    # Self administration
    self._grant_role(DEFAULT_ADMIN_ROLE, self)

    # Optional admin
    if (admin != empty(address)):
        self._grant_role(DEFAULT_ADMIN_ROLE, admin)

    # Register proposers and cancellers
    for proposer in proposers:
        self._grant_role(PROPOSER_ROLE, proposer)
        self._grant_role(CANCELLER_ROLE, proposer)

    # Register executors
    for executor in executors:
        self._grant_role(EXECUTOR_ROLE, executor)

    self._minDelay = minDelay
    log MinDelayChange(0, minDelay)

@external
@payable
def __default__():
    pass

@internal
def _onlyRoleOrOpenRole(role: bytes32):
    if (not(self.hasRole[role][empty(address)])):
        self._check_role(role, msg.sender)

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

# TODO: Most helper funtions below are originally public, but Vyper doesn't support that. wat do?

@external
@view
def isOperation(id: bytes32) -> bool:
    return self._isOperation(id)

@internal
@view
def _isOperation(id: bytes32) -> bool:
    return self._getOperationState(id) != OperationState.Unset

@external
@view
def isOperationPending(id: bytes32) -> bool:
    return self._isOperationPending(id)

@internal
@view
def _isOperationPending(id: bytes32) -> bool:
    state: OperationState = self._getOperationState(id)
    return state == OperationState.Waiting or state == OperationState.Ready

@external
@view
def isOperationReady(id: bytes32) -> bool:
    return self._isOperationReady(id)

@internal
@view
def _isOperationReady(id: bytes32) -> bool:
    return self._getOperationState(id) == OperationState.Ready

@external
@view
def isOperationDone(id: bytes32) -> bool:
    return self._isOperationDone(id)

@internal
@view
def _isOperationDone(id: bytes32) -> bool:
    return self._getOperationState(id) == OperationState.Done

@external
@view
def getTimestamp(id: bytes32) -> uint256:
    return self._getTimestamp(id)

@internal
@view
def _getTimestamp(id: bytes32) -> uint256:
    return self._timestamps[id]

@external
@pure
def hashOperation(target: address, x: uint256, data: Bytes[1_024], predecessor: bytes32, salt: bytes32) -> bytes32:
    return self._hashOperation(target, x, data, predecessor, salt)

@internal
@pure
def _hashOperation(target: address, x: uint256, data: Bytes[1_024], predecessor: bytes32, salt: bytes32) -> bytes32:
    value: uint256 = x
    return keccak256(_abi_encode(target, value, data, predecessor, salt))

@external
@pure
def hashOperationBatch(targets: DynArray[address, 128], values: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128], predecessor: bytes32, salt: bytes32) -> bytes32:
    return self._hashOperationBatch(targets, values, payloads, predecessor, salt)

@internal
@pure
def _hashOperationBatch(targets: DynArray[address, 128], values: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128], predecessor: bytes32, salt: bytes32) -> bytes32:
    return keccak256(_abi_encode(targets, values, payloads, predecessor, salt))

@external
@view
def getOperationState(id: bytes32) -> OperationState:
    return self._getOperationState(id)

@internal
@view
def _getOperationState(id: bytes32) -> OperationState:
    timestamp: uint256 = self._getTimestamp(id)
    if (timestamp == 0):
        return OperationState.Unset
    elif (timestamp == _DONE_TIMESTAMP):
        return OperationState.Done
    elif (timestamp > block.timestamp):
        return OperationState.Waiting
    else:
        return OperationState.Ready

@external
@view
def getMinDelay() -> uint256:
    return self._minDelay

@external
def schedule(target: address, x: uint256, data: Bytes[1_024], predecessor: bytes32, salt: bytes32, delay: uint256):
    self._check_role(PROPOSER_ROLE, msg.sender)
    value: uint256 = x
    id: bytes32 = self._hashOperation(target, value, data, predecessor, salt)
    self._schedule(id, delay)
    log CallScheduled(id, 0, target, value, data, predecessor, delay)
    if (salt != empty(bytes32)):
        log CallSalt(id, salt)

@external
def scheduleBatch(targets: DynArray[address, 128], values: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128], predecessor: bytes32, salt: bytes32, delay: uint256):
    self._check_role(PROPOSER_ROLE, msg.sender)
    assert len(targets) == len(values) and len(targets) == len(payloads), "TimelockController: invalid operation length"
    id: bytes32 = self._hashOperationBatch(targets, values, payloads, predecessor, salt)
    self._schedule(id, delay)
    idx: uint256 = empty(uint256)
    for target in targets:
        log CallScheduled(id, idx, target, values[idx], payloads[idx], predecessor, delay)
        # The following line cannot overflow because we have
        # limited the dynamic array.
        idx = unsafe_add(idx, 1)
    if (salt != empty(bytes32)):
        log CallSalt(id, salt)

@internal
def _schedule(id: bytes32, delay: uint256):
    assert not(self._isOperation(id)), "TimelockController: operation already scheduled"
    assert delay >= self._minDelay, "TimelockController: insufficient delay"
    self._timestamps[id] = block.timestamp + delay

@external
def cancel(id: bytes32):
    self._check_role(CANCELLER_ROLE, msg.sender)
    assert self._isOperationPending(id), "TimelockController: operation cannot be cancelled"
    self._timestamps[id] = 0
    log Cancelled(id)

@external
def execute(target: address, x: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32):
    self._onlyRoleOrOpenRole(EXECUTOR_ROLE)
    value: uint256 = x
    id: bytes32 = self._hashOperation(target, value, payload, predecessor, salt)

    self._beforeCall(id, predecessor)
    self._execute(target, value, payload)
    log CallExecuted(id, 0, target, value, payload)
    self._afterCall(id)

@external
def executeBatch(targets: DynArray[address, 128], values: DynArray[uint256, 128], payloads: DynArray[Bytes[1_024], 128], predecessor: bytes32, salt: bytes32):
    self._onlyRoleOrOpenRole(EXECUTOR_ROLE)
    assert len(targets) == len(values) and len(targets) == len(payloads), "TimelockController: invalid operation length"
    id: bytes32 = self._hashOperationBatch(targets, values, payloads, predecessor, salt)

    self._beforeCall(id, predecessor)
    idx: uint256 = empty(uint256)
    for target in targets:
        self._execute(target, values[idx], payloads[idx])
        log CallExecuted(id, idx, target, values[idx], payloads[idx])
        # The following line cannot overflow because we have
        # limited the dynamic array.
        idx = unsafe_add(idx, 1)
    self._afterCall(id)

@internal
def _execute(target: address, x: uint256, payload: Bytes[1_024]):
    value: uint256 = x
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    success, return_data = raw_call(target, payload, max_outsize=255, revert_on_failure=False)
    assert success, "TimelockController: underlying transaction reverted"

@internal
@view
def _beforeCall(id: bytes32, predecessor: bytes32):
    assert self._isOperationReady(id), "TimelockController: operation is not ready"
    assert predecessor == empty(bytes32) or self._isOperationDone(predecessor), "TimelockController: predecessor operation is not done"

@internal
def _afterCall(id: bytes32):
    assert self._isOperationReady(id), "TimelockController: operation is not ready"
    self._timestamps[id] = _DONE_TIMESTAMP

@external
def updateDelay(newDelay: uint256):
    assert msg.sender == self, "TimelockController: unauthorized"
    log MinDelayChange(self._minDelay, newDelay)
    self._minDelay = newDelay

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
def _check_role(role: bytes32, account: address):
    """
    @dev Reverts with a standard message if `account`
         is missing `role`.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    assert self.hasRole[role][account], "AccessControl: account is missing role"


@internal
def _set_role_admin(role: bytes32, admin_role: bytes32):
    """
    @dev Sets `admin_role` as `role`'s admin role.
    @notice This is an `internal` function without
            access restriction.
    @param role The 32-byte role definition.
    @param admin_role The new 32-byte admin role definition.
    """
    previous_admin_role: bytes32 = self.getRoleAdmin[role]
    self.getRoleAdmin[role] = admin_role
    log RoleAdminChanged(role, previous_admin_role, admin_role)


@internal
def _grant_role(role: bytes32, account: address):
    """
    @dev Grants `role` to `account`.
    @notice This is an `internal` function without
            access restriction.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    if (not(self.hasRole[role][account])):
        self.hasRole[role][account] = True
        log RoleGranted(role, account, msg.sender)


@internal
def _revoke_role(role: bytes32, account: address):
    """
    @dev Revokes `role` from `account`.
    @notice This is an `internal` function without
            access restriction.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    if (self.hasRole[role][account]):
        self.hasRole[role][account] = False
        log RoleRevoked(role, account, msg.sender)
