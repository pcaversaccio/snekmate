# pragma version ^0.3.10
"""
@title EIP-1155 Interface Definition
@custom:contract-name IERC1155
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The required interface definition of an ERC-1155
        compliant smart contract as defined in:
        https://eips.ethereum.org/EIPS/eip-1155. Note that
        smart contracts implementing the ERC-1155 standard
        must implement all of the functions in the ERC-1155
        interface. For more details, please refer to:
        https://eips.ethereum.org/EIPS/eip-1155#specification.

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


# @dev Emitted when `_value` tokens of token type
# `_id` are transferred from `_from` to `_to` by
# `_operator`.
event TransferSingle:
    _operator: indexed(address)
    _from: indexed(address)
    _to: indexed(address)
    _id: uint256
    _value: uint256


# @dev Equivalent to multiple `TransferSingle` events,
# where `_operator`, `_from`, and `_to` are the same
# for all transfers.
event TransferBatch:
    _operator: indexed(address)
    _from: indexed(address)
    _to: indexed(address)
    _ids: DynArray[uint256, 128]
    _values: DynArray[uint256, 128]


# @dev Emitted when `_owner` grants or revokes permission
# to `_operator` to transfer their tokens, according to
# `_approved`.
event ApprovalForAll:
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool


# @dev Emitted when the Uniform Resource Identifier (URI)
# for token type `_id` changes to `_value`, if it is a
# non-programmatic URI. Note that if an `URI` event was
# emitted for `_id`, the EIP-1155 standard guarantees that
# `_value` will equal the value returned by {IERC1155MetadataURI-uri}.
event URI:
    _value: String[512]
    _id: indexed(uint256)


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
def safeTransferFrom(_from: address, _to: address, _id: uint256, _value: uint256, _data: Bytes[1_024]):
    """
    @dev Transfers `_value` tokens of token type `_id` from
         `_from` to `_to`.
    @notice Note that `_to` cannot be the zero address. Also,
            if the caller is not `_from`, it must have been
            approved to spend `_from`'s tokens via `setApprovalForAll`.
            Furthermore, `_from` must have a balance of tokens
            of type `_id` of at least `_value`. Eventually, if
            `_to` refers to a smart contract, it must implement
            {IERC1155Receiver-onERC1155Received} and return the
            acceptance magic value.

            WARNING: This function can potentially allow a reentrancy
            attack when transferring tokens to an untrusted contract,
            when invoking {IERC1155Receiver-onERC1155Received} on the
            receiver. Ensure to follow the checks-effects-interactions
            (CEI) pattern and consider employing reentrancy guards when
            interacting with untrusted contracts.
    @param _from The 20-byte address which previously
           owned the token.
    @param _to The 20-byte receiver address.
    @param _id The 32-byte identifier of the token.
    @param _value The 32-byte token amount that is
           being transferred.
    @param _data The maximum 1,024-byte additional data
           with no specified format.
    """
    pass


@external
def safeBatchTransferFrom(_from: address, _to: address, _ids: DynArray[uint256, 128], _values: DynArray[uint256, 128], _data: Bytes[1_024]):
    """
    @dev Batched version of `safeTransferFrom`.
    @notice Note that `_ids` and `_values` must have the
            same length. Also, if `_to` refers to a smart
            contract, it must implement {IERC1155Receiver-onERC1155BatchReceived}
            and return the acceptance magic value.

            WARNING: This function can potentially allow a reentrancy
            attack when transferring tokens to an untrusted contract,
            when invoking {IERC1155Receiver-onERC1155BatchReceived} on
            the receiver. Ensure to follow the checks-effects-interactions
            (CEI) pattern and consider employing reentrancy guards when
            interacting with untrusted contracts.
    @param _from The 20-byte address which previously
           owned the token.
    @param _to The 20-byte receiver address.
    @param _ids The 32-byte array of token identifiers. Note
           that the order and length must match the 32-byte
           `_values` array.
    @param _values The 32-byte array of token amounts that are being
           transferred. Note that the order and length must match
           the 32-byte `_ids` array.
    @param _data The maximum 1,024-byte additional data
           with no specified format.
    """
    pass


@external
@view
def balanceOf(_owner: address, _id: uint256) -> uint256:
    """
    @dev Returns the amount of tokens of token type
         `_id` owned by `_owner`.
    @notice Note that `_owner` cannot be the zero
            address.
    @param _owner The 20-byte owner address.
    @param _id The 32-byte identifier of the token.
    @return uint256 The 32-byte token amount owned
            by `_owner`.
    """
    return empty(uint256)


@external
@view
def balanceOfBatch(_owners: DynArray[address, 128], _ids: DynArray[uint256, 128]) -> DynArray[uint256, 128]:
    """
    @dev Batched version of `balanceOf`.
    @notice Note that `_owners` and `_ids` must have the
            same length.
    @param _owners The 20-byte array of owner addresses.
    @param _ids The 32-byte array of token identifiers.
    @return DynArray The 32-byte array of token amounts
            owned by `_owners`.
    """
    return empty(DynArray[uint256, 128])


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @dev Grants or revokes permission to `_operator` to
         transfer the caller's tokens, according to `_approved`.
    @notice Note that `_operator` cannot be the caller.
    @param _operator The 20-byte operator address.
    @param _approved The Boolean variable that sets the
           approval status.
    """
    pass


@external
@view
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @dev Returns `True` if `_operator` is approved to transfer
         `_owner`'s tokens.
    @notice Note that `_operator` cannot be the caller.
    @param _owner The 20-byte owner address.
    @param _operator The 20-byte operator address.
    @return bool The verification whether `_operator` is approved
            or not.
    """
    return empty(bool)
