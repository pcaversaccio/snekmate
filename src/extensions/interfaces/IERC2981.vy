# @version ^0.3.9
"""
@title EIP-2981 Interface Definition
@custom:contract-name IERC2981
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The ERC-2981 introduces a standardised way to retrieve
        royalty payment information for non-fungible tokens (NFTs)
        to enable universal support for royalty payments across
        all NFT marketplaces and ecosystem participants. For more
        details, please refer to:
        https://eips.ethereum.org/EIPS/eip-2981.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


@external
@view
def royaltyInfo() -> (address, uint256):
    """
    @dev Returns the fields and values that describe the domain
         separator used by this contract for EIP-712 signatures.
    @notice The bits in the 1-byte bit map are read from the least
            significant to the most significant, and fields are indexed
            in the order that is specified by EIP-712, identical to the
            order in which they are listed in the function type.
    @param TBD
    @param TBD
    @return address The 20-byte address of the verifying contract.
    @return uint256 The 32-byte EIP-155 chain ID.
    """
    return (empty(address), empty(uint256))
