# @version ^0.3.7
"""
@title EIP-721 Optional Metadata Interface Definition
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice The metadata extension is optional for an ERC-721
        smart contract. This allows a smart contract to
        be interrogated for its name and for details about
        the asset(s) which a non-fungible token (NFT)
        represents. For more details, please refer to:
        https://eips.ethereum.org/EIPS/eip-721#specification.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


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
