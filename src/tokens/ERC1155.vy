# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-1155 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio, jtriley.eth
@notice These functions implement the ERC-1155
    standard interface:
    - https://eips.ethereum.org/EIPS/eip-1155.
    In addition, the following functions have
    been added for convenience:
    - `is_minter` (`external` function),
    - `safe_mint` (`external` function),
    - `set_minter` (`external` function),
    - `owner` (`external` function),
    - `transfer_ownership` (`external` function),
    - `renounce_ownership` (`external` function),
    - `_check_on_erc1155_received` (`internal` function),
    - `_check_on_erc1155_batch_received` (`internal` function),
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
    0x0E89341C, # The ERC-165 identifier for ERC-1155 metadata extension.
]

# @dev Stores the base URI for computing `tokenURI`.
_BASE_URI: immutable(String[80])


# @dev Mapping from token ID to token supply.
_supply_of_token_id: HashMap[uint256, uint256]


# @dev Mapping from owner address to token ID to token count.
_balances: HashMap[address, HashMap[uint256, uint256]]


# @dev Mapping from token ID to token URI.
# @notice Since the Vyper design requires
# strings of fixed size, we arbitrarily set
# the maximum length for `_token_uris` to 432
# characters. Since we have set the maximu,
# length for `_BASE_URI` to 80 characters,
# which implies a maximum character length
# for `tokenURI` of 512.
_token_uris: HashMap[uint256, String[432]]


# @dev Mapping from owner to operator to boolean indicating permission.
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])


# @dev Returns `True` if an `address` has been
# granted the minter role.
is_minter: public(HashMap[address, bool])


# @dev Returns address of the current owner.
owner: public(address)


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
    ids: DynArray[uint256, max_value(uint16)]
    amounts: DynArray[uint256, max_value(uint16)]


# @dev Emitted when `owner` grants or revokes permission
# to `operator` to transfer their tokens, according to
# `approved`.
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


# @dev Emitted when the Uniform Resource Identifier (URI)
# for token type `id` changes to `amount`, if it is a
# non-programmatic URI. Note that if an `URI` event was
# emitted for `id`, the EIP-1155 standard guarantees that
# `amount` will equal the value returned by `uri`.
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
           string base URI for computing `tokenURI`.
    """
    _BASE_URI = base_uri_
    self.owner = msg.sender
    self.is_minter[msg.sender] = True

    # TODO: consider if these should be logged here for indexers
    # log OwnershipTransferred(empty(address), msg.sender)
    # log RoleMinterChanged(msg.sender, True)


@external
@pure
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
def safeTransferFrom(owner: address, to: address, id: uint256, amount: uint256, data: Bytes[1024]):
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
    @param owner The 20-byte address which previously
            owned the token.
    @param to The 20-byte receiver address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount that is
            being transferred.
    @param data The maximum 1024-byte additional data
            with no specified format.
    """
    assert owner == msg.sender or self.isApprovedForAll[owner][msg.sender], "ERC1155: caller is not token owner or approved"
    self._safe_transfer_from(owner, to, id, amount, data)

@external
def safeBatchTransferFrom(
    owner: address,
    to: address,
    ids: DynArray[uint256, max_value(uint16)],
    amounts: DynArray[uint256, max_value(uint16)],
    data: Bytes[1024]
):
    """
    @dev Batched version of `safeTransferFrom`.
    @notice Note that `ids` and `amounts` must have the
            same length. Also, if `to` refers to a smart
            contract, it must implement {IERC1155Receiver-onERC1155Received}
            and return the acceptance magic value.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are being
           transferred. Note that the order and length must match
           the 32-byte `ids` array.
    @param data The maximum 1024-byte additional data
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
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @return uint256 The 32-byte token amount owned
        by `owner`.
    """
    assert owner != empty(address), "ERC1155: address zero is not a valid owner"
    return self._balances[owner][id]


@external
@view
def balanceOfBatch(owners: DynArray[address, max_value(uint16)], ids: DynArray[uint256, max_value(uint16)]) -> DynArray[uint256, max_value(uint16)]:
    """
    @dev Batched version of `balanceOf`.
    @notice Note that `owners` and `ids` must have the
            same length.
    @param owners The 20-byte array of owner addresses.
    @param ids The 32-byte array of token identifiers.
    @return DynArray The 32-byte array of token amounts
            owned by `owners`.
    """
    assert len(owners) == len(ids), "ERC1155: batch lengths mismatch"
    batch_balances: DynArray[uint256, max_value(uint16)] = []
    idx: uint256 = 0
    for owner in owners:
        id: uint256 = ids[idx]
        batch_balances[idx] = IERC1155(self).balanceOf(owner, id)
        # can never overflow, as the max length of the
        # owners array is less than max uint256
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
    assert msg.sender != operator, "ERC1155: approve to caller"
    self.isApprovedForAll[msg.sender][operator] = approved
    log ApprovalForAll(msg.sender, operator, approved)


@external
@view
def uri(id: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for token type `id`.
    @notice If the `id` substring is present in the URI,
            it must be replaced by clients with the actual
            token type ID. Note that the `uri` function must
            not be used to check for the existence of a token
            as it is possible for an implementation to return
            a valid string even if the token does not exist.
    @param id The 32-byte identifier of the token type `id`.
    @return String The maximum 512-character user-readable
            string token URI of the token type `id`.
    """
    assert self._supply_of_token_id[id] != empty(uint256), "ERC1155: invalid token ID"

    token_uri: String[432] = self._token_uris[id]

    # If there is no base URI, return the token URI.
    if (len(_BASE_URI) == empty(uint256)):
        return token_uri
    # If both are set, concatenate the base URI and token URI.
    elif (len(token_uri) != empty(uint256)):
        return concat(_BASE_URI, token_uri)
    # If there is no token URI but a base URI, concatenate the base URI and token ID.
    return concat(_BASE_URI, uint2str(id))


@external
def set_uri(id: uint256, uri: String[432]):
    """
    @dev Sets token URI for a given `token_id`.
    @notice This is decoupled from the `mint` function
            since multiple of the same `token_id` may be
            minted. However, permissions are shared with
            `is_minter`. Only minters have authorization
            to change token URIs.
    @param token_id The 32-byte token identifier.
    @param uri The maximum 432-character user-readable
           string URI for computing `tokenURI`.
    """
    assert self.is_minter[msg.sender], "ERC1155: not authorized to set token URI"
    self._token_uris[id] = uri
    log URI(uri, id)


@external
def transfer_ownership(new_owner: address):
    """
    @dev Sourced from {Ownable-transfer_ownership}.
    @notice See {Ownable-transfer_ownership} for
            the function docstring.
    """
    assert msg.sender == self.owner, "Ownable: caller is not the owner"
    assert new_owner != empty(address), "Ownable: new owner is the zero address"
    old_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(old_owner, new_owner)


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
    assert msg.sender == self.owner, "Ownable: caller is not the owner"
    self.is_minter[msg.sender] = False
    old_owner: address = self.owner
    self.owner = empty(address)
    log OwnershipTransferred(old_owner, empty(address))


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
    assert msg.sender == self.owner, "AccessControl: caller is not the owner"
    assert minter != empty(address), "AccessControl: minter is the zero address"
    assert minter != msg.sender, "AccessControl: minter is owner address"
    self.is_minter[minter] = status
    log RoleMinterChanged(minter, status)


@external
def safe_mint(owner: address, id: uint256, amount: uint256, data: Bytes[1024]):
    """
    @dev Safely mints `token_id` and transfers it to `owner`.
    @notice Only authorised minters can access this function.
            Note that `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte amount that is being minted.
    @param data The maximum 1024-byte additional data
           with no specified format.
    """
    assert self.is_minter[msg.sender], "AccessControl: access is denied"
    self._mint(owner, id, amount, data)


@external
def safe_mint_batch(
    owner: address,
    ids: DynArray[uint256, max_value(uint16)],
    amounts: DynArray[uint256, max_value(uint16)],
    data: Bytes[1024]
):
    """
    @dev Safely mints an array of `token_ids` and transfers them to `owner`.
    @notice Only authorized minters can access this function.
            Note that `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @param ids The array of 32-byte identifiers of the tokens.
    @param amounts The array of 32-byte amounts that are being minted.
    @param data The maximum 1024-byte additional data
           with no specified format.
    """
    assert self.is_minter[msg.sender], "AccessControl: access is denied"
    self._mint_batch(owner, ids, amounts, data)


@internal
def _safe_transfer_from(owner: address, to: address, id: uint256, amount: uint256, data: Bytes[1024]):
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
    @param owner The 20-byte address which previously
            owned the token.
    @param to The 20-byte receiver address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount that is
            being transferred.
    @param data The maximum 1024-byte additional data
            with no specified format.
    """
    assert to != empty(address), "ERC1155: transfer to the zero address"
    assert self._balances[owner][id] >= amount, "ERC1155: insufficient balance for transfer"
    # cannot underflow due to above check.
    self._balances[owner][id] = unsafe_sub(self._balances[owner][id], amount)
    # cannot overflow due to total token supply check in `mint` function.
    self._balances[to][id] = unsafe_add(self._balances[to][id], amount)
    log TransferSingle(msg.sender, owner, to, id, amount)
    assert self._check_on_erc1155_received(owner, to, id, amount, data), "ERC1155: transfer to non-ERC1155Receiver implementer"


@internal
def _safe_batch_transfer_from(
    owner: address,
    to: address,
    ids: DynArray[uint256, max_value(uint16)],
    amounts: DynArray[uint256, max_value(uint16)],
    data: Bytes[1024]
):
    """
    @dev Batched version of `safeTransferFrom`.
    @notice Note that `ids` and `amounts` must have the
            same length. Also, if `to` refers to a smart
            contract, it must implement {IERC1155Receiver-onERC1155Received}
            and return the acceptance magic value.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are being
           transferred. Note that the order and length must match
           the 32-byte `ids` array.
    @param data The maximum 1024-byte additional data
           with no specified format.
    """
    assert to != empty(address), "ERC1155: transfer to the zero address"
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"

    idx: uint256 = 0
    for id in ids:
        amount: uint256 = amounts[idx]
        assert self._balances[owner][id] >= amount, "ERC1155: insufficient balance"
        # cannot underflow due to above check.
        self._balances[owner][id] = unsafe_sub(self._balances[owner][id], amount)
        # cannot overflow due to total token supply check in `mint` function.
        self._balances[to][id] = unsafe_add(self._balances[to][id], amount)
        # can never overflow, as the max length of the
        # ids array is less than max uint256
        idx = unsafe_add(idx, 1)

    log TransferBatch(msg.sender, owner, to, ids, amounts)
    assert self._check_on_erc1155_batch_received(owner, to, ids, amounts, data), "ERC1155: transfer to non-ERC1155Receiver implementer"


@internal
def _mint(owner: address, id: uint256, amount: uint256, data: Bytes[1024]):
    """
    @dev Safely mints `token_id` and transfers it to `owner`.
    @notice Only authorised minters can access this function.
            Note that `owner` cannot be the zero address.
            Also, new tokens will be automatically assigned
            an incremental ID.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @param uri The maximum 432-character user-readable
           string URI for computing `tokenURI`.
    """
    assert owner != empty(address), "ERC1155: mint to the zero address"
    # checked addition here prevents all overflows on balance transfers
    self._supply_of_token_id[id] += amount
    # cannot overflow due to total token supply check above
    self._balances[owner][id] = unsafe_add(self._balances[owner][id], amount)
    log TransferSingle(msg.sender, empty(address), owner, id, amount)
    assert self._check_on_erc1155_received(empty(address), owner, id, amount, data), "ERC1155: mint to non-ERC1155Receiver implementer"


@internal
def _mint_batch(
    owner: address,
    ids: DynArray[uint256, max_value(uint16)],
    amounts: DynArray[uint256, max_value(uint16)],
    data: Bytes[1024]
):
    """
    @dev Safely mints an array of `token_ids` and transfers them to `owner`.
    @notice Only authorized minters can access this function.
            Note that `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @param ids The array of 32-byte identifiers of the tokens.
    @param amounts The array of 32-byte amounts that are being minted.
    @param data The maximum 1024-byte additional data
           with no specified format.
    """
    assert owner != empty(address), "ERC1155: mint to the zero address"
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"

    idx: uint256 = 0
    for id in ids:
        amount: uint256 = amounts[idx]
        # checked addition here prevents all overflows on balance transfers
        self._supply_of_token_id[id] += amount
        # cannot overflow due to total token supply check above
        self._balances[owner][id] = unsafe_add(self._balances[owner][id], amount)
        # can never overflow, as the max length of the
        # ids array is less than max uint256
        idx = unsafe_add(idx, 1)

    log TransferBatch(msg.sender, empty(address), owner, ids, amounts)
    assert self._check_on_erc1155_batch_received(empty(address), owner, ids, amounts, data), "ERC1155: transfer to non-ERC1155Receiver implementer"


@internal
def _check_on_erc1155_received(owner: address, to: address, token_id: uint256, amount: uint256, data: Bytes[1024]) -> bool:
    """
    @dev An `internal` function that invokes {IERC1155Receiver-onERC1155Received}
         on a target address. The call is not executed
         if the target address is not a contract.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    @param amount The 32-byte token amount to be transferred.
    @param data The maximum 1024-byte additional data
           with no specified format.
    @return The verification whether the call correctly
            returned the expected magic value.
    """
    # Contract case.
    if (to.is_contract):
        return_value: bytes4 = IERC1155Receiver(to).onERC1155Received(msg.sender, owner, token_id, amount, data)
        return return_value == method_id("onERC1155Received(address,address,uint256,uint256,bytes)", output_type=bytes4)
    # EOA case.
    return True


@internal
def _check_on_erc1155_batch_received(owner: address, to: address, token_ids: DynArray[uint256, max_value(uint16)], amounts: DynArray[uint256, max_value(uint16)], data: Bytes[1024]) -> bool:
    """
    @dev An `internal` function that invokes {IERC1155Receiver-onERC1155BatchReceived}
         on a target address. The call is not executed
         if the target address is not a contract.
    @param owner: The 20-byte address which previously
           owned the tokens.
    @param to The 20-byte receiver address.
    @param token_ids The array of 32-byte identifiers of the tokens.
    @param amounts The array of 32-byte token amounts to be transferred.
    @param data The maximum 1024-byte additional data
           with no specified format.
    @return The verification whether the call correctly
            returned the expected magic value.
    """
    # Contract case.
    if (to.is_contract):
        return_value: bytes4 = IERC1155Receiver(to).onERC1155BatchReceived(msg.sender, owner, token_ids, amounts, data)
        return return_value == method_id("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)", output_type=bytes4)
    # EOA case.
    return True

