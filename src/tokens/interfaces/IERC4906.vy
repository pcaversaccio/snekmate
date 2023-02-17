# @version ^0.3.7
"""
@title EIP-4906 Interface Definition
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice The ERC-4906 standard is an extension of EIP-721.
        It adds a `MetadataUpdate` event to EIP-721 tokens.
        The ERC-165 identifier for this interface is 0x49064906.
        For more details, please refer to:
        https://eips.ethereum.org/EIPS/eip-4906.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev Emitted when the metadata of a token is changed.
# Thus, third-party platforms, such as NFT marketplaces,
# can update the images and associated attributes of the
# NFT in a timely manner.
event MetadataUpdate:
    _tokenId: uint256


# @dev Emitted when the metadata of a range of tokens is
# changed. Thus, third-party platforms, such as NFT marketplaces,
# can update the images and associated attributes of the
# NFTs in a timely manner.
event BatchMetadataUpdate:
    _fromTokenId: uint256
    _toTokenId: uint256


@external
@view
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interface_id`.
    @notice For more details on how these identifiers are
            created, please refer to:
            https://eips.ethereum.org/EIPS/eip-165.
    @param interface_id The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return empty(bool)
