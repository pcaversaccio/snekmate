# pragma version ^0.3.10
"""
@title EIP-721 Optional Enumeration Interface Definition
@custom:contract-name IERC721Enumerable
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The enumeration extension is optional for an ERC-721
        smart contract. This allows a contract to publish its
        full list of ERC-721 tokens and make them discoverable.
        For more details, please refer to:
        https://eips.ethereum.org/EIPS/eip-721#specification.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import the `ERC721` interface, which is a built-in
# interface of the Vyper compiler, to highlight the association
# of the custom `IERC721Enumerable` interface with the built-in
# `ERC721` interface.
# @notice The interface `IERC721Enumerable` must be used in conjunction
# with the built-in interface `ERC721` to be EIP-721 compatible.
# If you want to use this interface as a stand-alone interface,
# you must add `implements: ERC721` to this interface and implement
# all required events and functions accordingly.
from vyper.interfaces import ERC721


@external
@view
def supportsInterface(interfaceId: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interfaceId`.
    @notice For more details on how these identifiers are
            created, please refer to:
            https://eips.ethereum.org/EIPS/eip-165.
    @param interfaceId The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return empty(bool)


@external
@view
def totalSupply() -> uint256:
    """
    @dev Returns the amount of tokens in existence.
    @return uint256 The 32-byte token supply.
    """
    return empty(uint256)


@external
@view
def tokenByIndex(_index: uint256) -> uint256:
    """
    @dev Returns a token ID at a given `_index` of
         all the tokens stored by the contract.
    @notice Use along with `totalSupply` to enumerate
            all tokens.
    @param _index The 32-byte counter (must be less
           than `totalSupply()`).
    @return uint256 The 32-byte token ID at index
            `_index`.
    """
    return empty(uint256)


@external
@view
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
    """
    @dev Returns a token ID owned by `_owner` at a
         given `_index` of its token list.
    @notice Use along with `balanceOf` to enumerate
            all of `_owner`'s tokens.
    @param _owner The 20-byte owner address.
    @param _index The 32-byte counter (must be less
           than `balanceOf(_owner)`).
    @return uint256 The 32-byte token ID owned by
            `_owner` at index `_index`.
    """
    return empty(uint256)
