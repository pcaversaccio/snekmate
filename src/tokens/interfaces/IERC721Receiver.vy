# pragma version ^0.3.10
"""
@title EIP-721 Token Receiver Interface Definition
@custom:contract-name IERC721Receiver
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The interface definition for any contract
        that wants to support safe transfers from
        ERC-721 asset contracts. For more details,
        please refer to:
        https://eips.ethereum.org/EIPS/eip-721#specification.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


@external
def onERC721Received(_operator: address, _from: address, _tokenId: uint256, _data: Bytes[1_024]) -> bytes4:
    """
    @dev Whenever a `_tokenId` token is transferred to
         this contract via `safeTransferFrom` by
         `_operator` from `_from`, this function is called.
    @notice It must return its function selector to
            confirm the token transfer. If any other value
            is returned or the interface is not implemented
            by the recipient, the transfer will be reverted.
    @param _operator The 20-byte address which called
           the `safeTransferFrom` function.
    @param _from The 20-byte address which previously
           owned the token.
    @param _tokenId The 32-byte identifier of the token.
    @param _data The maximum 1,024-byte additional data
           with no specified format.
    @return bytes4 The 4-byte function selector of `onERC721Received`.
    """
    return empty(bytes4)
