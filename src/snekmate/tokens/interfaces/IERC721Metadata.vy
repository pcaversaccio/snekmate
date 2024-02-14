# pragma version ^0.3.10
"""
@title EIP-721 Optional Metadata Interface Definition
@custom:contract-name IERC721Metadata
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The metadata extension is optional for an ERC-721
        smart contract. This allows a smart contract to
        be interrogated for its name and for details about
        the asset(s) which a non-fungible token (NFT)
        represents. For more details, please refer to:
        https://eips.ethereum.org/EIPS/eip-721#specification.

        Note that Vyper interfaces that implement functions
        with return values that require an upper bound (e.g.
        `Bytes`, `DynArray`, or `String`), the upper bound
        defined in the interface represents the lower bound
        of the implementation:
        https://github.com/vyperlang/vyper/pull/3205.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import the `ERC721` interface, which is a built-in
# interface of the Vyper compiler, to highlight the association
# of the custom `IERC721Metadata` interface with the built-in
# `ERC721` interface.
# @notice The interface `IERC721Metadata` must be used in conjunction
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
def name() -> String[25]:
    """
    @dev Returns the token collection name.
    @return String The maximum 25-character
            user-readable string name of the
            token collection.
    """
    return empty(String[25])


@external
@view
def symbol() -> String[5]:
    """
    @dev Returns the token collection symbol.
    @return String The maximum 5-character
            user-readable string symbol of the
            token collection.
    """
    return empty(String[5])


@external
@view
def tokenURI(_tokenId: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for `_tokenId` token.
    @notice Throws if `_tokenId` is not a valid ERC-721 token.
    @param _tokenId The 32-byte identifier of the token.
    @return String The maximum 512-character user-readable
            string token URI of the `_tokenId` token.
    """
    return empty(String[512])
