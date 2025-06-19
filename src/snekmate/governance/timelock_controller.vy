# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Multi-Role-Based Timelock Controller Reference Implementation
@custom:contract-name timelock_controller
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@custom:coauthor cairoeth
@notice This module enables the timelocking of operations by scheduling
        and executing transactions. By leveraging `access_control`, the
        `timelock_controller` contract introduces three roles:
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

        Please note that the `timelock_controller` contract is able to receive
        and transfer ERC-721 and ERC-1155 tokens.

        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol.
"""


# @dev We import and implement the `IERC165` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC165
implements: IERC165


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


# @dev We import and use the `access_control` module.
from ..auth import access_control
uses: access_control


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# (with the exception of the `supportsInterface` function)
# from the `access_control` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: (
    access_control.DEFAULT_ADMIN_ROLE,
    access_control.hasRole,
    access_control.getRoleAdmin,
    access_control.grantRole,
    access_control.revokeRole,
    access_control.renounceRole,
    access_control.set_role_admin,
)


# @dev The 32-byte proposer role.
# @notice Responsible for proposing operations.
# If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
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
IERC1155_TOKENRECEIVER_BATCH_SELECTOR: public(constant(bytes4)) = 0xBC197C81


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
# @notice Flags (a.k.a. Enums) are treated differently
# in Vyper and Solidity. The members are represented by
# `uint256` values (in Solidity the values are of type
# `uint8`) in the form `2**n`, where `n` is the index of
# the member in the range `0 <= n <= 255` (i.e. the first
# index value is `1`). For further insights also, see
# the following X thread:
# https://x.com/pcaversaccio/status/1626514029094047747.
flag OperationState:
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


@deploy
@payable
def __init__(
    minimum_delay_: uint256,
    proposers_: DynArray[address, _DYNARRAY_BOUND],
    executors_: DynArray[address, _DYNARRAY_BOUND],
    admin_: address,
):
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
    access_control._grant_role(access_control.DEFAULT_ADMIN_ROLE, self)

    # Revoke the `DEFAULT_ADMIN_ROLE` role from the deployer account.
    # The underlying reason for this design is that deployer accounts may
    # forget to revoke the admin rights from the timelock controller contract
    # after deployment. For further insights also, see the following issue:
    # https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3720.
    access_control._revoke_role(access_control.DEFAULT_ADMIN_ROLE, msg.sender)

    # Set the optional admin.
    if admin_ != empty(address):
        access_control._grant_role(access_control.DEFAULT_ADMIN_ROLE, admin_)

    # Register the proposers and cancellers.
    for proposer: address in proposers_:
        access_control._grant_role(PROPOSER_ROLE, proposer)
        access_control._grant_role(CANCELLER_ROLE, proposer)

    # Register the executors.
    for executor: address in executors_:
        access_control._grant_role(EXECUTOR_ROLE, executor)

    # Set the minimum delay.
    self.get_minimum_delay = minimum_delay_
    log MinimumDelayChange(old_duration=empty(uint256), new_duration=minimum_delay_)


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
def hash_operation(
    target: address, amount: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32
) -> bytes32:
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
def hash_operation_batch(
    targets: DynArray[address, _DYNARRAY_BOUND],
    amounts: DynArray[uint256, _DYNARRAY_BOUND],
    payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
    predecessor: bytes32,
    salt: bytes32,
) -> bytes32:
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
def schedule(
    target: address, amount: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32, delay: uint256
):
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
    access_control._check_role(PROPOSER_ROLE, msg.sender)
    id: bytes32 = self._hash_operation(target, amount, payload, predecessor, salt)

    self._schedule(id, delay)
    log CallScheduled(
        id=id, index=empty(uint256), target=target, amount=amount, payload=payload, predecessor=predecessor, delay=delay
    )
    if salt != empty(bytes32):
        log CallSalt(id=id, salt=salt)


@external
def schedule_batch(
    targets: DynArray[address, _DYNARRAY_BOUND],
    amounts: DynArray[uint256, _DYNARRAY_BOUND],
    payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
    predecessor: bytes32,
    salt: bytes32,
    delay: uint256,
):
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
    access_control._check_role(PROPOSER_ROLE, msg.sender)
    assert ((len(targets) == len(amounts)) and (len(targets) == len(payloads))), "timelock_controller: length mismatch"
    id: bytes32 = self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)

    self._schedule(id, delay)
    idx: uint256 = empty(uint256)
    for target: address in targets:
        log CallScheduled(
            id=id,
            index=idx,
            target=target,
            amount=amounts[idx],
            payload=payloads[idx],
            predecessor=predecessor,
            delay=delay,
        )
        # The following line cannot overflow because we have
        # limited the dynamic array `targets` by the `constant`
        # parameter `_DYNARRAY_BOUND`, which is bounded by the
        # maximum value of `uint8`.
        idx = unsafe_add(idx, 1)
    if salt != empty(bytes32):
        log CallSalt(id=id, salt=salt)


@external
def cancel(id: bytes32):
    """
    @dev Cancels an operation.
    @notice Note that the caller must have the `CANCELLER_ROLE` role.
    @param id The 32-byte operation identifier.
    """
    access_control._check_role(CANCELLER_ROLE, msg.sender)
    assert self._is_operation_pending(id), "timelock_controller: operation cannot be cancelled"
    self.get_timestamp[id] = empty(uint256)
    log Cancelled(id=id)


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
    log CallExecuted(id=id, index=empty(uint256), target=target, amount=amount, payload=payload)
    self._after_call(id)


@external
@payable
def execute_batch(
    targets: DynArray[address, _DYNARRAY_BOUND],
    amounts: DynArray[uint256, _DYNARRAY_BOUND],
    payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
    predecessor: bytes32,
    salt: bytes32,
):
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
    assert ((len(targets) == len(amounts)) and (len(targets) == len(payloads))), "timelock_controller: length mismatch"
    id: bytes32 = self._hash_operation_batch(targets, amounts, payloads, predecessor, salt)

    self._before_call(id, predecessor)
    idx: uint256 = empty(uint256)
    for target: address in targets:
        self._execute(target, amounts[idx], payloads[idx])
        log CallExecuted(id=id, index=idx, target=target, amount=amounts[idx], payload=payloads[idx])
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
    @notice Note that the caller must be the `timelock_controller`
            contract itself. This can only be achieved by scheduling
            and later executing an operation where the `timelock_controller`
            contract is the target and the payload is the ABI-encoded
            call to this function.
    @param new_delay The new 32-byte minimum delay in seconds.
    """
    assert msg.sender == self, "timelock_controller: caller must be timelock"
    log MinimumDelayChange(old_duration=self.get_minimum_delay, new_duration=new_delay)
    self.get_minimum_delay = new_delay


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
def onERC1155BatchReceived(
    operator: address,
    owner: address,
    ids: DynArray[uint256, 65_535],
    amounts: DynArray[uint256, 65_535],
    data: Bytes[1_024],
) -> bytes4:
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
    return ((state == OperationState.WAITING) or (state == OperationState.READY))


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
    if timestamp == empty(uint256):
        return OperationState.UNSET
    elif timestamp == _DONE_TIMESTAMP:
        return OperationState.DONE
    elif timestamp > block.timestamp:
        return OperationState.WAITING

    return OperationState.READY


@internal
@pure
def _hash_operation(
    target: address, amount: uint256, payload: Bytes[1_024], predecessor: bytes32, salt: bytes32
) -> bytes32:
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
    return keccak256(abi_encode(target, amount, payload, predecessor, salt))


@internal
@pure
def _hash_operation_batch(
    targets: DynArray[address, _DYNARRAY_BOUND],
    amounts: DynArray[uint256, _DYNARRAY_BOUND],
    payloads: DynArray[Bytes[1_024], _DYNARRAY_BOUND],
    predecessor: bytes32,
    salt: bytes32,
) -> bytes32:
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
    return keccak256(abi_encode(targets, amounts, payloads, predecessor, salt))


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
    assert not self._is_operation(id), "timelock_controller: operation already scheduled"
    assert delay >= self.get_minimum_delay, "timelock_controller: insufficient delay"
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
    success: bool = empty(bool)
    return_data: Bytes[max_value(uint8)] = b""
    success, return_data = raw_call(target, payload, max_outsize=255, value=amount, revert_on_failure=False)
    if not success:
        if len(return_data) != empty(uint256):
            # Bubble up the revert reason.
            raw_revert(return_data)

        raise "timelock_controller: underlying transaction reverted"


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
    assert self._is_operation_ready(id), "timelock_controller: operation is not ready"
    assert (
        predecessor == empty(bytes32) or self._is_operation_done(predecessor)
    ), "timelock_controller: missing dependency"


@internal
def _after_call(id: bytes32):
    """
    @dev Implements safety checks that must succeed after
         executing (an) operation call(s).
    @param id The 32-byte operation identifier.
    """
    assert self._is_operation_ready(id), "timelock_controller: operation is not ready"
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
    if not access_control.hasRole[role][empty(address)]:
        access_control._check_role(role, msg.sender)
