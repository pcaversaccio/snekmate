# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `ERC721` interface,
# which is a built-in interface of the Vyper compiler.
# @notice We do not import the interface `IERC721Metadata`
# (https://github.com/pcaversaccio/snekmate/blob/main/src/tokens/interfaces/IERC721Metadata.vy)
# to be able to declare `name` and `symbol` as
# `immutable` variables. This is a known compiler
# bug (https://github.com/vyperlang/vyper/issues/3130)
# and we will import the interface `IERC721Metadata`
# once it is fixed.
from vyper.interfaces import ERC721
implements: ERC721


# @dev We import and implement the `IERC721Enumerable`
# interface, which is written using standard Vyper
# syntax.
# import interfaces.IERC721Enumerable as IERC721Enumerable
# implements: IERC721Enumerable


# @dev We import and implement the `IERC721Permit`
# interface, which is written using standard Vyper
# syntax.
# import interfaces.IERC721Permit as IERC721Permit
# implements: IERC721Permit


# @dev We import the `IERC721Receiver` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC721Receiver as IERC721Receiver


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[5]) = [
    0x01ffc9a7, # The ERC-165 identifier for ERC-165.
    0x80ac58cd, # The ERC-165 identifier for ERC-721.
    0x5b5e139f, # The ERC-165 identifier for ERC-721 metadata extension.
    0x780e9d63, # The ERC-165 identifier for ERC-721 enumeration extension.
    0x589c5ce2, # The ERC-165 identifier for ERC-4494.
]


# @dev Returns the token collection name.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable. Furthermore,
# to preserve consistency with the interface for
# the optional metadata functions of the ERC-721
# standard, we use lower case letters for the
# `immutable` variables `name` and `symbol`.
name: public(immutable(String[25]))


# @dev Returns the token collection symbol.
# @notice See comment on lower case letters
# above at `name`.
symbol: public(immutable(String[5]))


# @dev Stores the base URI for computing `tokenURI`.
_BASE_URI: immutable(String[25])


# @dev Mapping from owner to operator approvals.
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])


# @dev Mapping from owner address to token count.
_balances: HashMap[address, uint256]


# @dev Mapping from token ID to owner address.
_owners: HashMap[uint256, address]


# @dev Mapping from token ID to approved address.
_token_approvals: HashMap[uint256, address]


# @dev Emitted when `token_id` token is
# transferred from `owner` to `to`.
event Transfer:
    owner: indexed(address)
    to: indexed(address)
    token_id: indexed(uint256)


# @dev Emitted when `owner` enables `approved`
# to manage the `token_id` token.
event Approval:
    owner: indexed(address)
    approved: indexed(address)
    token_id: indexed(uint256)


# @dev Emitted when `owner` enables or disables
# (`approved`) `operator` to manage all of its
# assets.
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


@external
@payable
def __init__(name_: String[25], symbol_: String[5], base_uri_: String[25]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice TBD
    @param name_ The maximum 25-byte user-readable string
           name of the token collection.
    @param symbol_ The maximum 5-byte user-readable string
           symbol of the token collection.
    @param base_uri_ The maximum 25-byte user-readable string
            base URI for computing `tokenURI`.
    """
    name = name_
    symbol = symbol_
    _BASE_URI = base_uri_


@external
@pure
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns true if this contract implements the
         interface defined by `interface_id`.
    @param interface_id The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return interface_id in _SUPPORTED_INTERFACES


@external
@view
def balanceOf(owner: address) -> uint256:
    """
    @dev Returns the amount of tokens owned by `owner`.
    @notice Note that `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte token amount owned
            by `owner`.
    """
    assert owner != empty(address), "ERC721: the zero address is not a valid owner"
    return self._balances[owner]


@external
@view
def ownerOf(token_id: uint256) -> address:
    """
    @dev Returns the owner of the `token_id` token.
    @notice Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    @return address The 20-byte owner address.
    """
    owner: address = self._owners[token_id]
    assert owner != empty(address), "ERC721: invalid token ID"
    return owner


@external
@view
def tokenURI(token_id: uint256) -> String[max_value(uint8)]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for `token_id` token.
    @notice Throws if `token_id` is not a valid ERC-721 token.  
    @param token_id The 32-byte identifier of the token.
    @return String The maximum 255-byte user-readable string
            token URI of the `token_id` token.
    """
    self._require_minted(token_id)
    if (len(_BASE_URI) > 0):
        return concat(_BASE_URI, uint2str(token_id))
    else:
        return ""


@external
@payable
def approve(to: address, token_id: uint256):
    owner: address = ERC721(self).ownerOf(token_id)
    assert to != owner, "ERC721: approval to current owner"
    assert owner == msg.sender or self.isApprovedForAll[owner][msg.sender], "ERC721: approve caller is not token owner or approved for all"
    self._approve(to, token_id)


@external
@view
def getApproved(token_id: uint256) -> address:
    self._require_minted(token_id)
    return self._token_approvals[token_id]


@external
def setApprovalForAll(operator: address, approved: bool):
    self._set_approval_for_all(msg.sender, operator, approved)


@external
@payable
def transferFrom(owner: address, to: address, token_id: uint256):
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
    self._transfer(owner, to, token_id)


@external
@payable
def safeTransferFrom(owner: address, to: address, token_id: uint256, data: Bytes[1024]):
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
    self._safe_transfer(owner, to, token_id, data)


@internal
@view
def _require_minted(token_id: uint256):
    """
    @dev Reverts if the `token_id` has not yet been minted.
    @param token_id The 32-byte identifier of the token.
    """
    assert self._exists(token_id), "ERC721: invalid token ID"


@internal
@view
def _exists(token_id: uint256) -> bool:
    """
    @dev Returns whether `token_id` exists.
    @notice Tokens can be managed by their owner or approved
            accounts via `approve` or `setApprovalForAll`.
            Tokens start existing when they are minted (`_mint`),
            and stop existing when they are burned (`_burn`).
    @param token_id The 32-byte identifier of the token.
    @return The verification whether `token_id` exists
            or not.
    """
    return self._owners[token_id] != empty(address)


@internal
def _approve(to: address, token_id: uint256):
    self._token_approvals[token_id] = to
    log Approval(ERC721(self).ownerOf(token_id), to, token_id)


@internal
def _set_approval_for_all(owner: address, operator: address, approved: bool):
    assert owner != operator, "ERC721: approve to caller"
    self.isApprovedForAll[owner][operator] = approved
    log ApprovalForAll(owner, operator, approved)


@internal
def _is_approved_or_owner(spender: address, token_id: uint256) -> bool:
    owner: address = ERC721(self).ownerOf(token_id)
    return (spender == owner or self.isApprovedForAll[owner][spender] or ERC721(self).getApproved(token_id) == spender)


@internal
def _safe_transfer(owner: address, to: address, token_id: uint256, data: Bytes[1024]):
    self._transfer(owner, to, token_id)
    

@internal
def _transfer(owner: address, to: address, token_id: uint256):
    assert ERC721(self).ownerOf(token_id) == owner, "ERC721: transfer from incorrect owner"
    assert to != empty(address), "ERC721: transfer to the zero address"
    
    self._before_token_transfer(owner, to, token_id)
    assert ERC721(self).ownerOf(token_id) == owner, "ERC721: transfer from incorrect owner"
    self._token_approvals[token_id] = empty(address)
    self._balances[owner] = unsafe_sub(self._balances[owner], 1)
    self._balances[to] = unsafe_add(self._balances[to], 1)
    self._owners[token_id] = to
    log Transfer(owner, to, token_id)

    self._after_token_transfer(owner, to, token_id)


@internal
def _before_token_transfer(owner: address, to: address, token_id: uint256):
    pass


@internal
def _after_token_transfer(owner: address, to: address, token_id: uint256):
    pass


@internal
def _check_on_erc721_received(owner: address, to: address, token_id: uint256, data: Bytes[1024]):
    if (to.is_contract):
        return_value: bytes4 = IERC721Receiver(to).onERC721Received(msg.sender, owner, token_id, data)
        assert return_value == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4)
