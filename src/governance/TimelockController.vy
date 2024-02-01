# pragma version ^0.3.10
"""
@title Multi-Role-Based Timelock Controller Reference Implementation
@custom:contract-name TimelockController
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@custom:coauthor cairoeth
@notice This module enables the timelocking of operations by scheduling
        and executing transactions. By leveraging `AccessControl`, the
        `TimelockController` contract introduces three roles:
          1. proposer (`PROPOSER_ROLE`),
          2. executor (`EXECUTOR_ROLE`), and
          3. canceller (`CANCELLER_ROLE`).
        The proposer role is responsible for proposing operations, the
        executor role is responsible for executing scheduled proposal(s),
        and the canceller is responsible for cancelling proposal(s). This
        contract is self-administered by default (unless an optional admin
        account is granted at construction), meaning administration tasks
        (e.g. grant or revoke roles) have to go through the timelock process.
        At contract creation time, proposers are granted the proposer and
        canceller roles.

        The proposal(s) must be scheduled with a delay that is greater
        than or equal to the minimum delay `get_minimum_delay`, which can
        be updated via a proposal to itself and is measured in seconds.
        Additionally, proposal(s) can be linked to preceding proposal(s)
        that must be executed before the proposal can be executed.

        Ready proposal(s) can be executed by the executor, who is solely
        responsible for calling the `execute` or `execute_batch` functions.
        Eventually, the proposal(s) can be batched individually or in batches.
        The latter is useful for processes that have to be executed in the
        same block.

        Please note that the `TimelockController` contract is able to receive
        and transfer ERC-721 and ERC-1155 tokens.

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


# @dev We import and implement the `IERC721Receiver`
# interface, which is written using standard Vyper
# syntax.
from ..tokens.interfaces import IERC721Receiver
implements: IERC721Receiver


# @dev We import and implement the `IERC1155Receiver`
# interface, which is written using standard Vyper
# syntax.
from ..tokens.interfaces import IERC1155Receiver
implements: IERC1155Receiver


# @dev The default 32-byte admin role.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
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


# @dev The 4-byte function selector of `onERC721Received(address,address,uint256,bytes)`.
IERC721_TOKENRECEIVER_SELECTOR: public(constant(bytes4)) = 0x150B7A02


# @dev The 4-byte function selector of `onERC1155Received(address,address,uint256,uint256,bytes)`.
IERC1155_TOKENRECEIVER_SINGLE_SELECTOR: public(constant(bytes4)) = 0xF23A6E61


# @dev The 4-byte function selector of `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)`.
IERC1155_TOKENRECEIVER_BATCH_SELECTOR:  public(constant(bytes4)) = 0xBC197C81


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
# @notice Note that the ERC-165 interface identifier for
# the `ERC721TokenReceiver` interface is not included as
# it is not required by the EIP:
# https://eips.ethereum.org/EIPS/eip-721#specification.
_SUPPORTED_INTERFACES: constant(bytes4[3]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0x7965DB0B, # The ERC-165 identifier for `IAccessControl`.
    0x4E2312E0, # The ERC-165 identifier for `IERC1155Receiver`.
]


# @dev The 32-byte timestamp that specifies whether a
# proposal has been executed.
_DONE_TIMESTAMP: constant(uint256) = 1


# @dev Stores the 1-byte upper bound for the dynamic arrays.
_DYNARRAY_BOUND: constant(uint8) = max_value(uint8)


# @dev The possible states of a proposal.
# @notice Enums are treated differently in Vyper and
# Solidity. The members are represented by `uint256`
# values (in Solidity the values are of type `uint8`)
# in the form `2**n`, where `n` is the index of the
# member in the range `0 <= n <= 255` (i.e. the first
# index value is `1`). For further insights also, see
# the following Twitter thread:
# https://twitter.com/pcaversaccio/status/1626514029094047747.
enum OperationState:
    UNSET
    WAITING
    READY
    DONE


# @dev Returns the timestamp at which an operation
# becomes ready (`0` for `UNSET` operations, `1` for
# `DONE` operations).
get_timestamp: public(HashMap[bytes32, uint256])


# @dev Returns the minimum delay in seconds for an
# operation to become valid. This value can be changed
# by executing an operation that invokes `update_delay`.
get_minimum_delay: public(uint256)


# @dev Returns `True` if `account` has been granted `role`.
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
    amount: uint256
    payload: Bytes[1_024]
    predecessor: bytes32
    delay: uint256


# @dev Emitted when a call is performed as part of
# operation `id`. Note that `index` is the index
# position of the proposal. If the proposal is
# individual, the `index` is `0`.
event CallExecuted:
    id: indexed(bytes32)
    index: indexed(uint256)
    target: address
    amount: uint256
    payload: Bytes[1_024]


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
def __init__(minimum_delay_: uint256, proposers_: DynArray[address, _DYNARRAY_BOUND], executors_: DynArray[address, _DYNARRAY_BOUND], admin_: address):
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
    @dev This contract might receive/hold ETH as part
         of the maintenance process.
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
def hash_operation(target: address, amount: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev Returns the identifier of an operation containing
         a single transaction.
    @param target The 20-bytes address of the target contract.
    @param amount The 32-byte amount of native tokens to transfer
           with the call.
    @param payload The maximum 1,024-byte ABI-encoded calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @return bytes32 The 32-byte hash of the operation.
    """
    return self._hash_operation(target, amount, payload, predecessor, salt)


@external
@pure
def hash_operation_batch(targets: DynArray[address, _DYNARRAY_BOUND], amounts: DynArray[uint256, _DYNARRAY_BOUND], payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
                         predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev Returns the identifier of an operation containing
         a batch of transactions.
    @param targets The 20-byte array of the target contracts.
    @param amounts The 32-byte array of native tokens amounts to
           transfer with each call.
    @param payloads The maximum 1,024-byte byte array of ABI-encoded
           calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @return bytes32 The 32-byte hash of the operation.
    """
    return self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)


@external
def schedule(target: address, amount: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32, delay: uint256):
    """
    @dev Schedules an operation containing a single transaction.
         Emits `CallScheduled` and `CallSalt` if the salt is non-zero.
    @notice Note that the caller must have the `PROPOSER_ROLE` role.
    @param target The 20-byte address of the target contract.
    @param amount The 32-byte amount of native tokens to transfer
           with the call.
    @param payload The maximum 1,024-byte ABI-encoded calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @param delay The 32-byte delay before the operation becomes valid.
           Must be greater than or equal to the minimum delay.
    """
    self._check_role(PROPOSER_ROLE, msg.sender)
    id: bytes32 = self._hash_operation(target, amount, payload, predecessor, salt)

    self._schedule(id, delay)
    log CallScheduled(id, empty(uint256), target, amount, payload, predecessor, delay)
    if (salt != empty(bytes32)):
        log CallSalt(id, salt)


@external
def schedule_batch(targets: DynArray[address, _DYNARRAY_BOUND], amounts: DynArray[uint256, _DYNARRAY_BOUND], payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
                   predecessor: bytes32, salt: bytes32, delay: uint256):
    """
    @dev Schedules an operation containing a batch of transactions.
         Emits one `CallScheduled` event per transaction in the
         batch and `CallSalt` if the salt is non-zero.
    @notice Note that the caller must have the `PROPOSER_ROLE` role.
    @param targets The 20-byte array of the target contracts.
    @param amounts The 32-byte array of native tokens amounts to
           transfer with each call.
    @param payloads The maximum 1,024-byte byte array of ABI-encoded
           calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @param delay The 32-byte delay before the operation becomes valid.
           Must be greater than or equal to the minimum delay.
    """
    self._check_role(PROPOSER_ROLE, msg.sender)
    assert len(targets) == len(amounts) and len(targets) == len(payloads), "TimelockController: length mismatch"
    id: bytes32 = self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)

    self._schedule(id, delay)
    idx: uint256 = empty(uint256)
    for target in targets:
        log CallScheduled(id, idx, target, amounts[idx], payloads[idx], predecessor, delay)
        # The following line cannot overflow because we have
        # limited the dynamic array `targets` by the `constant`
        # parameter `_DYNARRAY_BOUND`, which is bounded by the
        # maximum value of `uint8`.
        idx = unsafe_add(idx, 1)
    if (salt != empty(bytes32)):
        log CallSalt(id, salt)


@external
def cancel(id: bytes32):
    """
    @dev Cancels an operation.
    @notice Note that the caller must have the `CANCELLER_ROLE` role.
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
    @dev Executes a ready operation containing a single transaction.
         Emits a `CallExecuted` event.
    @notice Note that the caller must have the `EXECUTOR_ROLE` role.
    @param target The 20-byte address of the target contract.
    @param amount The 32-byte amount of native tokens to transfer
           with the call.
    @param payload The maximum 1,024-byte ABI-encoded calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @custom:security This function can reenter, but it doesn't pose
                     a risk because `_after_call` checks that the
                     proposal is pending, thus any modifications to
                     the operation during reentrancy are caught.
    """
    self._only_role_or_open_role(EXECUTOR_ROLE)
    id: bytes32 = self._hash_operation(target, amount, payload, predecessor, salt)

    self._before_call(id, predecessor)
    self._execute(target, amount, payload)
    log CallExecuted(id, empty(uint256), target, amount, payload)
    self._after_call(id)


@external
@payable
def execute_batch(targets: DynArray[address, _DYNARRAY_BOUND], amounts: DynArray[uint256, _DYNARRAY_BOUND], payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
                  predecessor: bytes32, salt: bytes32):
    """
    @dev Executes a ready operation containing a batch of transactions.
         Emits one `CallExecuted` event per transaction in the batch.
    @notice Note that the caller must have the `EXECUTOR_ROLE` role.
    @param targets The 20-byte array of the target contracts.
    @param amounts The 32-byte array of native tokens amounts to
           transfer with each call.
    @param payloads The maximum 1,024-byte byte array of ABI-encoded
           calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @custom:security This function can reenter, but it doesn't pose
                     a risk because `_after_call` checks that the
                     proposal is pending, thus any modifications to
                     the operation during reentrancy are caught.
    """
    self._only_role_or_open_role(EXECUTOR_ROLE)
    assert len(targets) == len(amounts) and len(targets) == len(payloads), "TimelockController: length mismatch"
    id: bytes32 = self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)

    self._before_call(id, predecessor)
    idx: uint256 = empty(uint256)
    for target in targets:
        self._execute(target, amounts[idx], payloads[idx])
        log CallExecuted(id, idx, target, amounts[idx], payloads[idx])
        # The following line cannot overflow because we have
        # limited the dynamic array `targets` by the `constant`
        # parameter `_DYNARRAY_BOUND`, which is bounded by the
        # maximum value of `uint8`.
        idx = unsafe_add(idx, 1)
    self._after_call(id)


@external
def update_delay(new_delay: uint256):
    """
    @dev Changes the minimum timelock duration for future
         operations. Emits a `MinimumDelayChange` event.
    @notice Note that the caller must be the `TimelockController`
            contract itself. This can only be achieved by scheduling
            and later executing an operation where the `TimelockController`
            contract is the target and the payload is the ABI-encoded
            call to this function.
    @param new_delay The new 32-byte minimum delay in seconds.
    """
    assert msg.sender == self, "TimelockController: caller must be timelock"
    log MinimumDelayChange(self.get_minimum_delay, new_delay)
    self.get_minimum_delay = new_delay


@external
def grantRole(role: bytes32, account: address):
    """
    @dev Sourced from {AccessControl-grantRole}.
    @notice See {AccessControl-grantRole} for the
            function docstring.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._grant_role(role, account)


@external
def revokeRole(role: bytes32, account: address):
    """
    @dev Sourced from {AccessControl-revokeRole}.
    @notice See {AccessControl-revokeRole} for the
            function docstring.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._revoke_role(role, account)


@external
def renounceRole(role: bytes32, account: address):
    """
    @dev Sourced from {AccessControl-renounceRole}.
    @notice See {AccessControl-renounceRole} for the
            function docstring.
    """
    assert account == msg.sender, "AccessControl: can only renounce roles for itself"
    self._revoke_role(role, account)


@external
def set_role_admin(role: bytes32, admin_role: bytes32):
    """
    @dev Sourced from {AccessControl-set_role_admin}.
    @notice See {AccessControl-set_role_admin} for the
            function docstring.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._set_role_admin(role, admin_role)


@external
def onERC721Received(operator: address, owner: address, token_id: uint256, data: Bytes[1_024]) -> bytes4:
    """
    @dev Whenever a `token_id` token is transferred to
         this contract via ERC-721 `safeTransferFrom` by
         `operator` from `owner`, this function is called.
    @notice It must return its function selector to
            confirm the token transfer. If any other value
            is returned or the interface is not implemented
            by the recipient, the transfer will be reverted.
    @param operator The 20-byte address which called
           the `safeTransferFrom` function.
    @param owner The 20-byte address which previously
           owned the token.
    @param token_id The 32-byte identifier of the token.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    @return bytes4 The 4-byte function selector of `onERC721Received`.
    """
    return IERC721_TOKENRECEIVER_SELECTOR


@external
def onERC1155Received(operator: address, owner: address, id: uint256, amount: uint256, data: Bytes[1_024]) -> bytes4:
    """
    @dev Handles the receipt of a single ERC-1155 token type.
         This function is called at the end of a `safeTransferFrom`
         after the balance has been updated.
    @notice It must return its function selector to
            confirm the token transfer. If any other value
            is returned or the interface is not implemented
            by the recipient, the transfer will be reverted.
    @param operator The 20-byte address which called
           the `safeTransferFrom` function.
    @param owner The 20-byte address which previously
           owned the token.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount that is
           being transferred.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    @return bytes4 The 4-byte function selector of `onERC1155Received`.
    """
    return IERC1155_TOKENRECEIVER_SINGLE_SELECTOR


@external
def onERC1155BatchReceived(operator: address, owner: address, ids: DynArray[uint256, 65_535], amounts: DynArray[uint256, 65_535],
                           data: Bytes[1_024]) -> bytes4:
    """
    @dev Handles the receipt of multiple ERC-1155 token types.
         This function is called at the end of a `safeBatchTransferFrom`
         after the balances have been updated.
    @notice It must return its function selector to
            confirm the token transfers. If any other value
            is returned or the interface is not implemented
            by the recipient, the transfers will be reverted.
    @param operator The 20-byte address which called
           the `safeBatchTransferFrom` function.
    @param owner The 20-byte address which previously
           owned the tokens.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being transferred. Note that the order and length must
           match the 32-byte `ids` array.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    @return bytes4 The 4-byte function selector of `onERC1155BatchReceived`.
    """
    return IERC1155_TOKENRECEIVER_BATCH_SELECTOR


@internal
@view
def _is_operation(id: bytes32) -> bool:
    """
    @dev Returns whether an `id` corresponds to a registered
         operation. This includes both `WAITING`, `READY`, and
         `DONE` operations.
    @param id The 32-byte operation identifier.
    @return bool The verification whether the `id`
            corresponds to a registered operation or not.
    """
    return self._get_operation_state(id) != OperationState.UNSET


@internal
@view
def _is_operation_pending(id: bytes32) -> bool:
    """
    @dev Returns whether an operation is pending or not.
         Note that a "pending" operation may also be
         "ready".
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
    @dev Returns whether an operation is ready for
         execution. Note that a "ready" operation is
         also "pending".
    @param id The 32-byte operation identifier.
    @return bool The verification whether the operation
            is ready or not.
    """
    return self._get_operation_state(id) == OperationState.READY


@internal
@view
def _is_operation_done(id: bytes32) -> bool:
    """
    @dev Returns whether an operation is done or not.
    @param id The 32-byte operation identifier.
    @return bool The verification whether the operation
            is done or not.
    """
    return self._get_operation_state(id) == OperationState.DONE


@internal
@view
def _get_operation_state(id: bytes32) -> OperationState:
    """
    @dev Returns the state of an operation.
    @param id The 32-byte operation identifier.
    @return OperationState The 32-byte state of the
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
def _hash_operation(target: address, amount: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev Returns the identifier of an operation containing
         a single transaction.
    @param target The 20-bytes address of the target contract.
    @param amount The 32-byte amount of native tokens to transfer
           with the call.
    @param payload The maximum 1,024-byte ABI-encoded calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @return bytes32 The 32-byte hash of the operation.
    """
    return keccak256(_abi_encode(target, amount, payload, predecessor, salt))


@internal
@pure
def _hash_operation_batch(targets: DynArray[address, _DYNARRAY_BOUND], amounts: DynArray[uint256, _DYNARRAY_BOUND], payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
                          predecessor: bytes32, salt: bytes32) -> bytes32:
    """
    @dev Returns the identifier of an operation containing
         a batch of transactions.
    @param targets The 20-byte array of the target contracts.
    @param amounts The 32-byte array of native tokens amounts to
           transfer with each call.
    @param payloads The maximum 1,024-byte byte array of ABI-encoded
           calldata.
    @param predecessor The 32-byte hash of the preceding operation
           (optional with empty bytes).
    @param salt The 32-byte salt of the operation.
    @return bytes32 The 32-byte hash of the operation.
    """
    return keccak256(_abi_encode(targets, amounts, payloads, predecessor, salt))


@internal
def _schedule(id: bytes32, delay: uint256):
    """
    @dev Schedules an operation that is to become valid
         after a given delay.
    @notice This is an `internal` function without access
            restriction.
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
    @dev Executes an operation call.
    @notice This is an `internal` function without access
            restriction.
    @param target The 20-byte address of the target contract.
    @param amount The 32-byte amount of native tokens to transfer
           with the call.
    @param payload The maximum 1,024-byte ABI-encoded calldata.
    """
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    success, return_data = raw_call(target, payload, max_outsize=255, value=amount, revert_on_failure=False)
    if (not(success)):
        if len(return_data) != empty(uint256):
            # Bubble up the revert reason.
            raw_revert(return_data)
        else:
            raise "TimelockController: underlying transaction reverted"


@internal
@view
def _before_call(id: bytes32, predecessor: bytes32):
    """
    @dev Implements safety checks that must succeed before
         executing (an) operation call(s).
    @param id The 32-byte operation identifier.
    @param predecessor The 32-byte hash of the preceding
           operation.
    """
    assert self._is_operation_ready(id), "TimelockController: operation is not ready"
    assert predecessor == empty(bytes32) or self._is_operation_done(predecessor), "TimelockController: missing dependency"


@internal
def _after_call(id: bytes32):
    """
    @dev Implements safety checks that must succeed after
         executing (an) operation call(s).
    @param id The 32-byte operation identifier.
    """
    assert self._is_operation_ready(id), "TimelockController: operation is not ready"
    self.get_timestamp[id] = _DONE_TIMESTAMP


@internal
@view
def _only_role_or_open_role(role: bytes32):
    """
    @dev Limits a function to be callable only by a certain
         role. In addition to checking the sender's role,
         the zero address `empty(address)` is also considered.
         Granting a role to `empty(address)` is equivalent to
         enabling this role for everyone.
    @param role The 32-byte role definition.
    """
    if (not(self.hasRole[role][empty(address)])):
        self._check_role(role, msg.sender)


@internal
@view
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
