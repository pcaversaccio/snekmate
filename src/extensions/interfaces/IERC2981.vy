# pragma version ^0.3.10
"""
@title EIP-2981 Interface Definition
@custom:contract-name IERC2981
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The ERC-2981 introduces a standardised way to retrieve
        royalty payment information for non-fungible tokens (NFTs)
        to enable universal support for royalty payments across
        all NFT marketplaces and ecosystem participants. The ERC-165
        identifier for this interface is `0x2A55205A`. For more
        details, please refer to:
        https://eips.ethereum.org/EIPS/eip-2981.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


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
def royaltyInfo(_tokenId: uint256, _salePrice: uint256) -> (address, uint256):
    """
    @dev Returns how much royalty is owed and to whom, based
         on a sale price that may be denominated in any unit
         of exchange. The royalty amount is denominated and
         should be paid in that same unit of exchange.
    @param _tokenId The 32-byte identifier of the token.
    @param _salePrice The 32-byte sale price of the NFT asset
           specified by `_tokenId`.
    @return address The 20-byte address of the recipient of
            the royalty payment.
    @return uint256 The 32-byte royalty payment amount for
            `_salePrice`.
    """
    return (empty(address), empty(uint256))
