# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


# @dev We import the `ERC165` interface, which
# is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import the `ERC721` interface, which
# is a built-in interface of the Vyper compiler.
# from vyper.interfaces import ERC721
# implements: ERC721


# @dev We import the `IERC721Metadata` interface, which
# is written using standard Vyper syntax.
# import interfaces.IERC721Metadata as IERC721Metadata
# implements: IERC721Metadata


# @dev We import the `IERC721Enumerable` interface, which
# is written using standard Vyper syntax.
# import interfaces.IERC721Enumerable as IERC721Enumerable
# implements: IERC721Enumerable


# @dev We import the `IERC721Permit` interface, which
# is written using standard Vyper syntax.
# import interfaces.IERC721Permit as IERC721Permit
# implements: IERC721Permit


# @dev We import the `IERC721Receiver` interface, which
# is written using standard Vyper syntax.
# import interfaces.IERC721Receiver as IERC721Receiver
# implements: IERC721Receiver


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


# @dev Mapping from owner address to token count.
_balances: HashMap[address, uint256]


# @dev Mapping from token ID to owner address.
_owners: HashMap[uint256, address]


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
    @dev TBD
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
    assert owner != empty(address), "ERC721: address zero is not a valid owner"
    return self._balances[owner]


@external
@view
def ownerOf(token_id: uint256) -> address:
    owner: address = self._owners[token_id]
    assert owner != empty(address), "ERC721: invalid token ID"
    return owner


@external
@view
def tokenURI(token_id: uint256) -> String[max_value(uint8)]:
    self._require_minted(token_id)
    if (len(_BASE_URI) > 0):
        return concat(_BASE_URI, uint2str(token_id))
    else:
        return ""


@internal
@view
def _require_minted(token_id: uint256):
    assert self._exists(token_id), "ERC721: invalid token ID"


@internal
@view
def _exists(token_id: uint256) -> bool:
    return self._owners[token_id] != empty(address)
