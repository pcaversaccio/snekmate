# pragma version ^0.3.10
"""
@title EIP-1155 Token Receiver Interface Definition
@custom:contract-name IERC1155Receiver
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The interface definition for any contract
        that wants to support safe transfers from
        ERC-1155 asset contracts. For more details,
        please refer to:
        https://eips.ethereum.org/EIPS/eip-1155#erc-1155-token-receiver.

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
def onERC1155Received(_operator: address, _from: address, _id: uint256, _value: uint256, _data: Bytes[1_024]) -> bytes4:
    """
    @dev Handles the receipt of a single ERC-1155 token type.
         This function is called at the end of a `safeTransferFrom`
         after the balance has been updated.
    @notice It must return its function selector to
            confirm the token transfer. If any other value
            is returned or the interface is not implemented
            by the recipient, the transfer will be reverted.
    @param _operator The 20-byte address which called
           the `safeTransferFrom` function.
    @param _from The 20-byte address which previously
           owned the token.
    @param _id The 32-byte identifier of the token.
    @param _value The 32-byte token amount that is
           being transferred.
    @param _data The maximum 1,024-byte additional data
           with no specified format.
    @return bytes4 The 4-byte function selector of `onERC1155Received`.
    """
    return empty(bytes4)


@external
def onERC1155BatchReceived(_operator: address, _from: address, _ids: DynArray[uint256, 65_535], _values: DynArray[uint256, 65_535],
                           _data: Bytes[1_024]) -> bytes4:
    """
    @dev Handles the receipt of multiple ERC-1155 token types.
         This function is called at the end of a `safeBatchTransferFrom`
         after the balances have been updated.
    @notice It must return its function selector to
            confirm the token transfers. If any other value
            is returned or the interface is not implemented
            by the recipient, the transfers will be reverted.
    @param _operator The 20-byte address which called
           the `safeBatchTransferFrom` function.
    @param _from The 20-byte address which previously
           owned the tokens.
    @param _ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `_values` array.
    @param _values The 32-byte array of token amounts that are
           being transferred. Note that the order and length must
           match the 32-byte `_ids` array.
    @param _data The maximum 1,024-byte additional data
           with no specified format.
    @return bytes4 The 4-byte function selector of `onERC1155BatchReceived`.
    """
    return empty(bytes4)
