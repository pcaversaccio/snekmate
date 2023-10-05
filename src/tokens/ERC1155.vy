# pragma version ^0.3.10
"""
@title Modern and Gas-Efficient ERC-1155 Implementation
@custom:contract-name ERC1155
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@custom:coauthor jtriley.eth
@notice These functions implement the ERC-1155
        standard interface:
        - https://eips.ethereum.org/EIPS/eip-1155.
        In addition, the following functions have
        been added for convenience:
        - `uri` (`external` `view` function),
        - `set_uri` (`external` function),
        - `total_supply` (`external` `view` function),
        - `exists` (`external` `view` function),
        - `burn` (`external` function),
        - `burn_batch` (`external` function),
        - `is_minter` (`external` `view` function),
        - `safe_mint` (`external` function),
        - `safe_mint_batch` (`external` function),
        - `set_minter` (`external` function),
        - `owner` (`external` `view` function),
        - `transfer_ownership` (`external` function),
        - `renounce_ownership` (`external` function),
        - `_check_on_erc1155_received` (`internal` function),
        - `_check_on_erc1155_batch_received` (`internal` function),
        - `_before_token_transfer` (`internal` function),
        - `_after_token_transfer` (`internal` function).
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `IERC1155` interface,
# which is written using standard Vyper syntax.
import interfaces.IERC1155 as IERC1155
implements: IERC1155


# @dev We import and implement the `IERC1155MetadataURI`
# interface, which is written using standard Vyper
# syntax.
import interfaces.IERC1155MetadataURI as IERC1155MetadataURI
implements: IERC1155MetadataURI


# @dev We import the `IERC1155Receiver` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC1155Receiver as IERC1155Receiver


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[3]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0xD9B67A26, # The ERC-165 identifier for ERC-1155.
    0x0E89341C, # The ERC-165 identifier for the ERC-1155 metadata extension.
]


# @dev Stores the upper bound for batch calls.
_BATCH_SIZE: constant(uint16) = 255


# @dev Stores the base URI for computing `uri`.
_BASE_URI: immutable(String[80])


# @dev Mapping from owner to operator approvals.
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])


# @dev Mapping from token ID to token supply.
total_supply: public(HashMap[uint256, uint256])


# @dev Returns `True` if an `address` has been
# granted the minter role.
is_minter: public(HashMap[address, bool])


# @dev Returns address of the current owner.
owner: public(address)


# @dev Mapping from token ID to owner balance.
_balances: HashMap[uint256, HashMap[address, uint256]]


# @dev Mapping from token ID to token URI.
# @notice Since the Vyper design requires
# strings of fixed size, we arbitrarily set
# the maximum length for `_token_uris` to 432
# characters. Since we have set the maximum
# length for `_BASE_URI` to 80 characters,
# which implies a maximum character length
# for `uri` of 512.
_token_uris: HashMap[uint256, String[432]]


# @dev Emitted when `amount` tokens of token type
# `id` are transferred from `owner` to `to` by
# `operator`.
event TransferSingle:
    operator: indexed(address)
    owner: indexed(address)
    to: indexed(address)
    id: uint256
    amount: uint256


# @dev Equivalent to multiple `TransferSingle` events,
# where `operator`, `owner`, and `to` are the same
# for all transfers.
event TransferBatch:
    operator: indexed(address)
    owner: indexed(address)
    to: indexed(address)
    ids: DynArray[uint256, _BATCH_SIZE]
    amounts: DynArray[uint256, _BATCH_SIZE]


# @dev Emitted when `owner` grants or revokes permission
# to `operator` to transfer their tokens, according to
# `approved`.
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


# @dev Emitted when the Uniform Resource Identifier (URI)
# for token type `id` changes to `value`, if it is a
# non-programmatic URI. Note that if an `URI` event was
# emitted for `id`, the EIP-1155 standard guarantees that
# `value` will equal the value returned by `uri`.
event URI:
    value: String[512]
    id: indexed(uint256)


# @dev Emitted when the ownership is transferred
# from `previous_owner` to `new_owner`.
event OwnershipTransferred:
    previous_owner: indexed(address)
    new_owner: indexed(address)


# @dev Emitted when the status of a `minter`
# address is changed.
event RoleMinterChanged:
    minter: indexed(address)
    status: bool


@external
@payable
def __init__(base_uri_: String[80]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @param base_uri_ The maximum 80-character user-readable
           string base URI for computing `uri`.
    """
    _BASE_URI = base_uri_

    self._transfer_ownership(msg.sender)
    self.is_minter[msg.sender] = True
    log RoleMinterChanged(msg.sender, True)


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
def safeTransferFrom(owner: address, to: address, id: uint256, amount: uint256, data: Bytes[1_024]):
    """
    @dev Transfers `amount` tokens of token type `id` from
         `owner` to `to`.
    @notice Note that `to` cannot be the zero address. Also,
            if the caller is not `owner`, it must have been
            approved to spend `owner`'s tokens via `setApprovalForAll`.
            Furthermore, `owner` must have a balance of tokens
            of type `id` of at least `amount`. Eventually, if
            `to` refers to a smart contract, it must implement
            {IERC1155Receiver-onERC1155Received} and return the
            acceptance magic value.

            WARNING: This function can potentially allow a reentrancy
            attack when transferring tokens to an untrusted contract,
            when invoking {IERC1155Receiver-onERC1155Received} on the
            receiver. We ensure that we consistently follow the checks-
            effects-interactions (CEI) pattern to avoid being vulnerable
            to this type of attack.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount that is
           being transferred.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert owner == msg.sender or self.isApprovedForAll[owner][msg.sender], "ERC1155: caller is not token owner or approved"
    self._safe_transfer_from(owner, to, id, amount, data)


@external
def safeBatchTransferFrom(owner: address, to: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE],
                          data: Bytes[1_024]):
    """
    @dev Batched version of `safeTransferFrom`.
    @notice Note that `ids` and `amounts` must have the
            same length. Also, if `to` refers to a smart
            contract, it must implement {IERC1155Receiver-onERC1155BatchReceived}
            and return the acceptance magic value.

            WARNING: This function can potentially allow a reentrancy
            attack when transferring tokens to an untrusted contract,
            when invoking {IERC1155Receiver-onERC1155BatchReceived} on
            the receiver. We ensure that we consistently follow the
            checks-effects-interactions (CEI) pattern to avoid being
            vulnerable to this type of attack.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being transferred. Note that the order and length must
           match the 32-byte `ids` array.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert owner == msg.sender or self.isApprovedForAll[owner][msg.sender], "ERC1155: caller is not token owner or approved"
    self._safe_batch_transfer_from(owner, to, ids, amounts, data)


@external
@view
def balanceOf(owner: address, id: uint256) -> uint256:
    """
    @dev Returns the amount of tokens of token type
         `id` owned by `owner`.
    @notice Note that `owner` cannot be the zero
            address.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @return uint256 The 32-byte token amount owned
            by `owner`.
    """
    return self._balance_of(owner, id)


@external
@view
def balanceOfBatch(owners: DynArray[address, _BATCH_SIZE], ids: DynArray[uint256, _BATCH_SIZE]) -> DynArray[uint256, _BATCH_SIZE]:
    """
    @dev Batched version of `balanceOf`.
    @notice Note that `owners` and `ids` must have the
            same length.
    @param owners The 20-byte array of owner addresses.
    @param ids The 32-byte array of token identifiers.
    @return DynArray The 32-byte array of token amounts
            owned by `owners`.
    """
    assert len(owners) == len(ids), "ERC1155: owners and ids length mismatch"
    batch_balances: DynArray[uint256, _BATCH_SIZE] = []
    idx: uint256 = empty(uint256)
    for owner in owners:
        batch_balances.append(self._balance_of(owner, ids[idx]))
        # The following line cannot overflow because we have
        # limited the dynamic array `owners` by the `constant`
        # parameter `_BATCH_SIZE`, which is bounded by the
        # maximum value of `uint16`.
        idx = unsafe_add(idx, 1)
    return batch_balances


@external
def setApprovalForAll(operator: address, approved: bool):
    """
    @dev Grants or revokes permission to `operator` to
         transfer the caller's tokens, according to `approved`.
    @notice Note that `operator` cannot be the caller.
    @param operator The 20-byte operator address.
    @param approved The Boolean variable that sets the
           approval status.
    """
    self._set_approval_for_all(msg.sender, operator, approved)


@external
@view
def uri(id: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for token type `id`.
    @notice If the `{id}` substring is present in the URI,
            it must be replaced by clients with the actual
            token type ID. Note that the `uri` function must
            not be used to check for the existence of a token
            as it is possible for the implementation to return
            a valid string even if the token does not exist.
    @param id The 32-byte identifier of the token type `id`.
    @return String The maximum 512-character user-readable
            string token URI of the token type `id`.
    """
    return self._uri(id)


@external
def set_uri(id: uint256, token_uri: String[432]):
    """
    @dev Sets the Uniform Resource Identifier (URI)
         for token type `id`.
    @notice This function is decoupled from `safe_mint`
            and `safe_mint_batch`, as multiple of the same
            `id` can be minted. However, the permissions
            are shared with `is_minter`. Only minters have
            the authorisation to change token URIs.
    @param id The 32-byte identifier of the token.
    @param token_uri The maximum 432-character user-readable
           string URI for computing `uri`.
    """
    assert self.is_minter[msg.sender], "AccessControl: access is denied"
    self._set_uri(id, token_uri)


@external
@view
def exists(id: uint256) -> bool:
    """
    @dev Indicates whether any token exist with a
         given `id` or not.
    @param id The 32-byte identifier of the token.
    @return bool The verification whether `id` exists
            or not.
    """
    return self.total_supply[id] != empty(uint256)


@external
def burn(owner: address, id: uint256, amount: uint256):
    """
    @dev Destroys `amount` tokens of token type `id`
         from `owner`.
    @notice Note that `owner` cannot be the zero
            address. Also, `owner` must have at least
            `amount` tokens of token type `id`.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount to be destroyed.
    """
    assert owner == msg.sender or self.isApprovedForAll[owner][msg.sender], "ERC1155: caller is not token owner or approved"
    self._burn(owner, id, amount)


@external
def burn_batch(owner: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE]):
    """
    @dev Batched version of `burn`.
    @notice Note that `ids` and `amounts` must have the
            same length.
    @param owner The 20-byte owner address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being destroyed. Note that the order and length must
           match the 32-byte `ids` array.
    """
    assert owner == msg.sender or self.isApprovedForAll[owner][msg.sender], "ERC1155: caller is not token owner or approved"
    self._burn_batch(owner, ids, amounts)


@external
def safe_mint(owner: address, id: uint256, amount: uint256, data: Bytes[1_024]):
    """
    @dev Safely mints `amount` tokens of token type `id` and
         transfers them to `owner`.
    @notice Only authorised minters can access this function.
            Note that `owner` cannot be the zero address. Also,
            if `owner` refers to a smart contract, it must implement
            {IERC1155Receiver-onERC1155Received}, which is called
            upon a safe transfer.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount to be created.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert self.is_minter[msg.sender], "AccessControl: access is denied"
    self._safe_mint(owner, id, amount, data)


@external
def safe_mint_batch(owner: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE], data: Bytes[1_024]):
    """
    @dev Batched version of `safe_mint`.
    @notice Note that `ids` and `amounts` must have the
            same length. Also, if `owner` refers to a smart contract,
            it must implement {IERC1155Receiver-onERC1155BatchReceived},
            which is called upon a safe transfer.
    @param owner The 20-byte owner address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being created. Note that the order and length must
           match the 32-byte `ids` array.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert self.is_minter[msg.sender], "AccessControl: access is denied"
    self._safe_mint_batch(owner, ids, amounts, data)


@external
def set_minter(minter: address, status: bool):
    """
    @dev Adds or removes an address `minter` to/from the
         list of allowed minters. Note that only the
         `owner` can add or remove `minter` addresses.
         Also, the `minter` cannot be the zero address.
         Eventually, the `owner` cannot remove himself
         from the list of allowed minters.
    @param minter The 20-byte minter address.
    @param status The Boolean variable that sets the status.
    """
    self._check_owner()
    assert minter != empty(address), "AccessControl: minter is the zero address"
    # We ensured in the previous step `self._check_owner()`
    # that `msg.sender` is the `owner`.
    assert minter != msg.sender, "AccessControl: minter is owner address"
    self.is_minter[minter] = status
    log RoleMinterChanged(minter, status)


@external
def transfer_ownership(new_owner: address):
    """
    @dev Transfers the ownership of the contract
         to a new account `new_owner`.
    @notice Note that this function can only be
            called by the current `owner`. Also,
            the `new_owner` cannot be the zero address.

            WARNING: The ownership transfer also removes
            the previous owner's minter role and assigns
            the minter role to `new_owner` accordingly.
    @param new_owner The 20-byte address of the new owner.
    """
    self._check_owner()
    assert new_owner != empty(address), "Ownable: new owner is the zero address"

    self.is_minter[msg.sender] = False
    log RoleMinterChanged(msg.sender, False)

    self._transfer_ownership(new_owner)
    self.is_minter[new_owner] = True
    log RoleMinterChanged(new_owner, True)


@external
def renounce_ownership():
    """
    @dev Leaves the contract without an owner.
    @notice Renouncing ownership will leave the
            contract without an owner, thereby
            removing any functionality that is
            only available to the owner. Note
            that the `owner` is also removed from
            the list of allowed minters.

            WARNING: All other existing `minter`
            addresses will still be able to create
            new tokens. Consider removing all non-owner
            minter addresses first via `set_minter`
            before calling `renounce_ownership`.
    """
    self._check_owner()
    self.is_minter[msg.sender] = False
    log RoleMinterChanged(msg.sender, False)
    self._transfer_ownership(empty(address))


@internal
def _set_approval_for_all(owner: address, operator: address, approved: bool):
    """
    @dev Grants or revokes permission to `operator` to
         transfer the `owner`'s tokens, according to `approved`.
    @notice Note that `operator` cannot be the `owner`.
    @param operator The 20-byte operator address.
    @param approved The Boolean variable that sets the
           approval status.
    """
    assert owner != operator, "ERC1155: setting approval status for self"
    self.isApprovedForAll[owner][operator] = approved
    log ApprovalForAll(owner, operator, approved)


@internal
def _safe_transfer_from(owner: address, to: address, id: uint256, amount: uint256, data: Bytes[1_024]):
    """
    @dev Transfers `amount` tokens of token type `id` from
         `owner` to `to`.
    @notice Note that `to` cannot be the zero address. Also,
            `owner` must have a balance of tokens of type `id`
            of at least `amount`. Furthermore, if `to` refers
            to a smart contract, it must implement {IERC1155Receiver-onERC1155Received}
            and return the acceptance magic value.

            WARNING: This `internal` function can potentially
            allow a reentrancy attack when transferring tokens
            to an untrusted contract, when invoking {IERC1155Receiver-onERC1155Received}
            on the receiver. We ensure that we consistently follow
            the checks-effects-interactions (CEI) pattern to avoid
            being vulnerable to this type of attack.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount that is
           being transferred.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert to != empty(address), "ERC1155: transfer to the zero address"

    self._before_token_transfer(owner, to, self._as_singleton_array(id), self._as_singleton_array(amount), data)

    owner_balance: uint256 = self._balances[id][owner]
    assert owner_balance >= amount, "ERC1155: insufficient balance for transfer"
    self._balances[id][owner] = unsafe_sub(owner_balance, amount)
    # In the next line, an overflow is not possible
    # due to an arithmetic check of the entire token
    # supply in the functions `_safe_mint` and `_safe_mint_batch`.
    self._balances[id][to] = unsafe_add(self._balances[id][to], amount)
    log TransferSingle(msg.sender, owner, to, id, amount)

    self._after_token_transfer(owner, to, self._as_singleton_array(id), self._as_singleton_array(amount), data)

    assert self._check_on_erc1155_received(owner, to, id, amount, data), "ERC1155: transfer to non-ERC1155Receiver implementer"


@internal
def _safe_batch_transfer_from(owner: address, to: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE],
                              data: Bytes[1_024]):
    """
    @dev Batched version of `_safe_transfer_from`.
    @notice Note that `ids` and `amounts` must have the
            same length. Also, if `to` refers to a smart
            contract, it must implement {IERC1155Receiver-onERC1155BatchReceived}
            and return the acceptance magic value.

            WARNING: This `internal` function can potentially
            allow a reentrancy attack when transferring tokens
            to an untrusted contract, when invoking {IERC1155Receiver-onERC1155BatchReceived}
            on the receiver. We ensure that we consistently follow
            the checks-effects-interactions (CEI) pattern to avoid
            being vulnerable to this type of attack.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being transferred. Note that the order and length must
           match the 32-byte `ids` array.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"
    assert to != empty(address), "ERC1155: transfer to the zero address"

    self._before_token_transfer(owner, to, ids, amounts, data)

    idx: uint256 = empty(uint256)
    for id in ids:
        amount: uint256 = amounts[idx]
        owner_balance: uint256 = self._balances[id][owner]
        assert owner_balance >= amount, "ERC1155: insufficient balance for transfer"
        self._balances[id][owner] = unsafe_sub(owner_balance, amount)
        # In the next line, an overflow is not possible
        # due to an arithmetic check of the entire token
        # supply in the functions `_safe_mint` and `_safe_mint_batch`.
        self._balances[id][to] = unsafe_add(self._balances[id][to], amount)
        # The following line cannot overflow because we have
        # limited the dynamic array `ids` by the `constant`
        # parameter `_BATCH_SIZE`, which is bounded by the
        # maximum value of `uint16`.
        idx = unsafe_add(idx, 1)

    log TransferBatch(msg.sender, owner, to, ids, amounts)

    self._after_token_transfer(owner, to, ids, amounts, data)

    assert self._check_on_erc1155_batch_received(owner, to, ids, amounts, data), "ERC1155: transfer to non-ERC1155Receiver implementer"


@internal
@view
def _balance_of(owner: address, id: uint256) -> uint256:
    """
    @dev An `internal` helper function that returns the
         amount of tokens of token type `id` owned by `owner`.
    @notice Note that `owner` cannot be the zero
            address.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @return uint256 The 32-byte token amount owned
            by `owner`.
    """
    assert owner != empty(address), "ERC1155: address zero is not a valid owner"
    return self._balances[id][owner]


@internal
def _safe_mint(owner: address, id: uint256, amount: uint256, data: Bytes[1_024]):
    """
    @dev Safely mints `amount` tokens of token type `id` and
         transfers them to `owner`.
    @notice This is an `internal` function without access
            restriction. Note that `owner` cannot be the zero address.
            Also, if `owner` refers to a smart contract, it must implement
            {IERC1155Receiver-onERC1155Received}, which is called
            upon a safe transfer.

            WARNING: This `internal` function without access
            restriction can potentially allow a reentrancy
            attack when transferring tokens to an untrusted
            contract, when invoking {IERC1155Receiver-onERC1155Received}
            on the receiver. We ensure that we consistently
            follow the checks-effects-interactions (CEI) pattern
            to avoid being vulnerable to this type of attack.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount to be created.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert owner != empty(address), "ERC1155: mint to the zero address"

    self._before_token_transfer(empty(address), owner, self._as_singleton_array(id), self._as_singleton_array(amount), data)

    # In the next line, an overflow is not possible
    # due to an arithmetic check of the entire token
    # supply in the function `_before_token_transfer`.
    self._balances[id][owner] = unsafe_add(self._balances[id][owner], amount)
    log TransferSingle(msg.sender, empty(address), owner, id, amount)

    self._after_token_transfer(empty(address), owner, self._as_singleton_array(id), self._as_singleton_array(amount), data)

    assert self._check_on_erc1155_received(empty(address), owner, id, amount, data), "ERC1155: mint to non-ERC1155Receiver implementer"


@internal
def _safe_mint_batch(owner: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE], data: Bytes[1_024]):
    """
    @dev Batched version of `_safe_mint`.
    @notice Note that `ids` and `amounts` must have the
            same length. Also, if `owner` refers to a smart contract,
            it must implement {IERC1155Receiver-onERC1155BatchReceived},
            which is called upon a safe transfer.

            WARNING: This `internal` function without access
            restriction can potentially allow a reentrancy
            attack when transferring tokens to an untrusted
            contract, when invoking {IERC1155Receiver-onERC1155BatchReceived}
            on the receiver. We ensure that we consistently
            follow the checks-effects-interactions (CEI) pattern
            to avoid being vulnerable to this type of attack.
    @param owner The 20-byte owner address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being created. Note that the order and length must
           match the 32-byte `ids` array.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"
    assert owner != empty(address), "ERC1155: mint to the zero address"

    self._before_token_transfer(empty(address), owner, ids, amounts, data)

    idx: uint256 = empty(uint256)
    for id in ids:
        # In the next line, an overflow is not possible
        # due to an arithmetic check of the entire token
        # supply in the function `_before_token_transfer`.
        self._balances[id][owner] = unsafe_add(self._balances[id][owner], amounts[idx])
        # The following line cannot overflow because we have
        # limited the dynamic array `ids` by the `constant`
        # parameter `_BATCH_SIZE`, which is bounded by the
        # maximum value of `uint16`.
        idx = unsafe_add(idx, 1)

    log TransferBatch(msg.sender, empty(address), owner, ids, amounts)

    self._after_token_transfer(empty(address), owner, ids, amounts, data)

    assert self._check_on_erc1155_batch_received(empty(address), owner, ids, amounts, data), "ERC1155: transfer to non-ERC1155Receiver implementer"


@internal
@view
def _uri(id: uint256) -> String[512]:
    """
    @dev An `internal` helper function that returns the Uniform
         Resource Identifier (URI) for token type `id`.
    @notice If the `{id}` substring is present in the URI,
            it must be replaced by clients with the actual
            token type ID. Note that the `uri` function must
            not be used to check for the existence of a token
            as it is possible for the implementation to return
            a valid string even if the token does not exist.
    @param id The 32-byte identifier of the token type `id`.
    @return String The maximum 512-character user-readable
            string token URI of the token type `id`.
    """
    token_uri: String[432] = self._token_uris[id]

    base_uri_length: uint256 = len(_BASE_URI)
    # If there is no base URI, return the token URI.
    if (base_uri_length == empty(uint256)):
        return token_uri

    # If both are set, concatenate the base URI
    # and token URI.
    if (len(token_uri) != empty(uint256)):
        return concat(_BASE_URI, token_uri)

    # If there is no token URI but a base URI,
    # concatenate the base URI and token ID.
    if (base_uri_length != empty(uint256)):
        # Please note that for projects where the
        # substring `{id}` is present in the URI
        # and this URI is to be set as `_BASE_URI`,
        # it is recommended to remove the following
        # concatenation and simply return `_BASE_URI`
        # for easier off-chain handling.
        return concat(_BASE_URI, uint2str(id))
    else:
        return ""


@internal
def _set_uri(id: uint256, token_uri: String[432]):
    """
    @dev Sets the Uniform Resource Identifier (URI)
         for token type `id`.
    @notice This is an `internal` function without access
            restriction. This function is decoupled from
            `_mint`, as multiple of the same `id` can be
            minted.
    @param id The 32-byte identifier of the token.
    @param token_uri The maximum 432-character user-readable
           string URI for computing `uri`.
    """
    self._token_uris[id] = token_uri
    log URI(self._uri(id), id)


@internal
def _burn(owner: address, id: uint256, amount: uint256):
    """
    @dev Destroys `amount` tokens of token type `id`
         from `owner`.
    @notice Note that `owner` cannot be the zero
            address. Also, `owner` must have at least
            `amount` tokens of token type `id`.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount to be destroyed.
    """
    assert owner != empty(address), "ERC1155: burn from the zero address"

    self._before_token_transfer(owner, empty(address), self._as_singleton_array(id), self._as_singleton_array(amount), b"")

    owner_balance: uint256 = self._balances[id][owner]
    assert owner_balance >= amount, "ERC1155: burn amount exceeds balance"
    self._balances[id][owner] = unsafe_sub(owner_balance, amount)
    log TransferSingle(msg.sender, owner, empty(address), id, amount)

    self._after_token_transfer(owner, empty(address), self._as_singleton_array(id), self._as_singleton_array(amount), b"")


@internal
def _burn_batch(owner: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE]):
    """
    @dev Batched version of `_burn`.
    @notice Note that `ids` and `amounts` must have the
            same length.
    @param owner The 20-byte owner address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being destroyed. Note that the order and length must
           match the 32-byte `ids` array.
    """
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"
    assert owner != empty(address), "ERC1155: burn from the zero address"

    self._before_token_transfer(owner, empty(address), ids, amounts, b"")

    idx: uint256 = empty(uint256)
    for id in ids:
        amount: uint256 = amounts[idx]
        owner_balance: uint256 = self._balances[id][owner]
        assert owner_balance >= amount, "ERC1155: burn amount exceeds balance"
        self._balances[id][owner] = unsafe_sub(owner_balance, amount)
        # The following line cannot overflow because we have
        # limited the dynamic array `ids` by the `constant`
        # parameter `_BATCH_SIZE`, which is bounded by the
        # maximum value of `uint16`.
        idx = unsafe_add(idx, 1)

    log TransferBatch(msg.sender, owner, empty(address), ids, amounts)

    self._after_token_transfer(owner, empty(address), ids, amounts, b"")


@internal
def _check_on_erc1155_received(owner: address, to: address, id: uint256, amount: uint256, data: Bytes[1_024]) -> bool:
    """
    @dev An `internal` function that invokes {IERC1155Receiver-onERC1155Received}
         on a target address. The call is not executed
         if the target address is not a contract.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount that is
           being transferred.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    @return bool The verification whether the call correctly
            returned the expected magic value.
    """
    # Contract case.
    if (to.is_contract):
        return_value: bytes4 = IERC1155Receiver(to).onERC1155Received(msg.sender, owner, id, amount, data)
        assert return_value == method_id("onERC1155Received(address,address,uint256,uint256,bytes)", output_type=bytes4),\
                                         "ERC1155: transfer to non-ERC1155Receiver implementer"
        return True
    # EOA case.
    else:
        return True


@internal
def _check_on_erc1155_batch_received(owner: address, to: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE],
                                     data: Bytes[1_024]) -> bool:
    """
    @dev An `internal` function that invokes {IERC1155Receiver-onERC1155BatchReceived}
         on a target address. The call is not executed
         if the target address is not a contract.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers.
    @param amounts The 32-byte array of token amounts that are
           being transferred.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    @return bool The verification whether the call correctly
            returned the expected magic value.
    """
    # Contract case.
    if (to.is_contract):
        return_value: bytes4 = IERC1155Receiver(to).onERC1155BatchReceived(msg.sender, owner, ids, amounts, data)
        assert return_value == method_id("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)", output_type=bytes4),\
                                         "ERC1155: transfer to non-ERC1155Receiver implementer"
        return True
    # EOA case.
    else:
        return True


@internal
def _before_token_transfer(owner: address, to: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE],
                           data: Bytes[1_024]):
    """
    @dev Hook that is called before any token transfer.
         This includes minting and burning, as well as
         batched variants.
    @notice Note that the same hook is called on both
            single and batched variants. For single transfers,
            the length of the `ids` and `amounts` arrays will
            be 1. The calling conditions for each `id` and
            `amount` pair are:
            - when `owner` and `to` are both non-zero, `amount` of
              `owner`'s tokens of token type `id` will be transferred
              to `to`,
            - when `owner` is zero, `amount` tokens of token type `id`
              will be minted for `to`,
            - when `to` is zero, `amount` of `owner`'s tokens of token
              type `id` will be burned,
            - `from` and `to` are never both zero,
            - `ids` and `amounts` have the same, non-zero length.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being transferred. Note that the order and length must
           match the 32-byte `ids` array.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    if (owner == empty(address)):
        idx: uint256 = empty(uint256)
        for id in ids:
            # The following line uses intentionally checked arithmetic
            # to ensure that the total supply for each token type `id`
            # never overflows.
            self.total_supply[id] += amounts[idx]
            # The following line cannot overflow because we have
            # limited the dynamic array `ids` by the `constant`
            # parameter `_BATCH_SIZE`, which is bounded by the
            # maximum value of `uint16`.
            idx = unsafe_add(idx, 1)

    if (to == empty(address)):
        idx: uint256 = empty(uint256)
        for id in ids:
            amount: uint256 = amounts[idx]
            supply: uint256 = self.total_supply[id]
            assert supply >= amount, "ERC1155: burn amount exceeds total_supply"
            self.total_supply[id] = unsafe_sub(supply, amount)
            # The following line cannot overflow because we have
            # limited the dynamic array `ids` by the `constant`
            # parameter `_BATCH_SIZE`, which is bounded by the
            # maximum value of `uint16`.
            idx = unsafe_add(idx, 1)


@internal
def _after_token_transfer(owner: address, to: address, ids: DynArray[uint256, _BATCH_SIZE], amounts: DynArray[uint256, _BATCH_SIZE],
                          data: Bytes[1_024]):
    """
    @dev Hook that is called after any token transfer.
         This includes minting and burning, as well as
         batched variants.
    @notice Note that the same hook is called on both
            single and batched variants. For single transfers,
            the length of the `ids` and `amounts` arrays will
            be 1. The calling conditions for each `id` and
            `amount` pair are:
            - when `owner` and `to` are both non-zero, `amount` of
              `owner`'s tokens of token type `id` will be transferred
              to `to`,
            - when `owner` is zero, `amount` tokens of token type `id`
              will be minted for `to`,
            - when `to` is zero, `amount` of `owner`'s tokens of token
              type `id` will be burned,
            - `from` and `to` are never both zero,
            - `ids` and `amounts` have the same, non-zero length.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are
           being transferred. Note that the order and length must
           match the 32-byte `ids` array.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    """
    pass


@internal
@pure
def _as_singleton_array(element: uint256) -> DynArray[uint256, 1]:
    """
    @dev An `internal` helper function that converts a 32-byte
         element into an array of length 1.
    @param element The 32-byte non-array element.
    @return DynArray The array of length 1 containing `element`.
    """
    return [element]


@internal
def _check_owner():
    """
    @dev Sourced from {Ownable-_check_owner}.
    @notice See {Ownable-_check_owner} for
            the function docstring.
    """
    assert msg.sender == self.owner, "Ownable: caller is not the owner"


@internal
def _transfer_ownership(new_owner: address):
    """
    @dev Sourced from {Ownable-_transfer_ownership}.
    @notice See {Ownable-_transfer_ownership} for
            the function docstring.
    """
    old_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(old_owner, new_owner)
