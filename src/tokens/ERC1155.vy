# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-1155 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `IERC1155` interface,
# which is written using standard Vyper syntax.
import interfaces.IERC1155 as IERC1155
implements: IERC1155


# @dev We import and implement the `IERC1155MetadataURI`
# interface, which is written using standard Vyper
# syntax.
import interfaces.IERC1155MetadataURI as IERC1155MetadataURI
implements: IERC1155MetadataURI


# @dev We import the `IERC1155Receiver` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC1155Receiver as IERC1155Receiver


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[3]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0xD9B67A26, # The ERC-165 identifier for ERC-1155.
    0x0E89341C, # The ERC-165 identifier for ERC-1155 metadata extension.
]


# @dev Emitted when `amount` tokens of token type
# `id` are transferred from `owner` to `to` by
# `operator`.
event TransferSingle:
    operator: indexed(address)
    owner: indexed(address)
    to: indexed(address)
    id: uint256
    amount: uint256


# @dev Equivalent to multiple `TransferSingle` events,
# where `operator`, `owner`, and `to` are the same
# for all transfers.
event TransferBatch:
    operator: indexed(address)
    owner: indexed(address)
    to: indexed(address)
    ids: DynArray[uint256, max_value(uint16)]
    amounts: DynArray[uint256, max_value(uint16)]


# @dev Emitted when `owner` grants or revokes permission
# to `operator` to transfer their tokens, according to
# `approved`.
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


# @dev Emitted when the Uniform Resource Identifier (URI)
# for token type `id` changes to `amount`, if it is a
# non-programmatic URI. Note that if an `URI` event was
# emitted for `id`, the EIP-1155 standard guarantees that
# `amount` will equal the value returned by `uri`.
event URI:
    amount: String[512]
    id: indexed(uint256)


@external
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@external
@pure
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interface_id`.
    @param interface_id The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return interface_id in _SUPPORTED_INTERFACES


@external
def safeTransferFrom(owner: address, to: address, id: uint256, amount: uint256, data: Bytes[1024]):
    """
    @dev Transfers `amount` tokens of token type `id` from
         `owner` to `to`.
    @notice Note that `to` cannot be the zero address. Also,
            if the caller is not `owner`, it must have been
            approved to spend `owner`'s tokens via `setApprovalForAll`.
            Furthermore, `owner` must have a balance of tokens
            of type `id` of at least `amount`. Eventually, if
            `to` refers to a smart contract, it must implement
            {IERC1155Receiver-onERC1155Received} and return the
            acceptance magic value.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param id The 32-byte identifier of the token.
    @param amount The 32-byte token amount that is
           being transferred.
    @param data The maximum 1024-byte additional data
           with no specified format.
    """
    pass


@external
def safeBatchTransferFrom(owner: address, to: address, ids: DynArray[uint256, max_value(uint16)], amounts: DynArray[uint256, max_value(uint16)],
                          data: Bytes[1024]):
    """
    @dev Batched version of `safeTransferFrom`.
    @notice Note that `ids` and `amounts` must have the
            same length. Also, if `to` refers to a smart
            contract, it must implement {IERC1155Receiver-onERC1155Received}
            and return the acceptance magic value.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte receiver address.
    @param ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `amounts` array.
    @param amounts The 32-byte array of token amounts that are being
           transferred. Note that the order and length must match
           the 32-byte `ids` array.
    @param data The maximum 1024-byte additional data
           with no specified format.
    """
    pass


@external
@view
def balanceOf(owner: address, id: uint256) -> uint256:
    """
    @dev Returns the amount of tokens of token type
         `id` owned by `owner`.
    @notice Note that `owner` cannot be the zero
            address.
    @param owner The 20-byte owner address.
    @param id The 32-byte identifier of the token.
    @return uint256 The 32-byte token amount owned
            by `owner`.
    """
    return empty(uint256)


@external
@view
def balanceOfBatch(owners: DynArray[address, max_value(uint16)], ids: DynArray[uint256, max_value(uint16)]) -> DynArray[uint256, max_value(uint16)]:
    """
    @dev Batched version of `balanceOf`.
    @notice Note that `owners` and `ids` must have the
            same length.
    @param owners The 20-byte array of owner addresses.
    @param ids The 32-byte array of token identifiers.
    @return DynArray The 32-byte array of token amounts
            owned by `owners`.
    """
    return empty(DynArray[uint256, max_value(uint16)])


@external
def setApprovalForAll(operator: address, approved: bool):
    """
    @dev Grants or revokes permission to `operator` to
         transfer the caller's tokens, according to `approved`.
    @notice Note that `operator` cannot be the caller.
    @param operator The 20-byte operator address.
    @param approved The Boolean variable that sets the
           approval status.
    """
    pass


@external
@view
def isApprovedForAll(owner: address, operator: address) -> bool:
    """
    @dev Returns `True` if `operator` is approved to transfer
         `owner`'s tokens.
    @notice Note that `operator` cannot be the caller.
    @param owner The 20-byte owner address.
    @param operator The 20-byte operator address.
    @return bool The verification whether `operator` is approved
            or not.
    """
    return empty(bool)


@external
@view
def uri(id: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for token type `id`.
    @notice If the `id` substring is present in the URI,
            it must be replaced by clients with the actual
            token type ID. Note that the `uri` function must
            not be used to check for the existence of a token
            as it is possible for an implementation to return
            a valid string even if the token does not exist.
    @param id The 32-byte identifier of the token type `id`.
    @return String The maximum 512-character user-readable
            string token URI of the token type `id`.
    """
    return empty(String[512])
