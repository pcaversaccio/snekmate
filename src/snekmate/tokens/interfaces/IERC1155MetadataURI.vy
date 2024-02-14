# pragma version ^0.3.10
"""
@title EIP-1155 Optional Metadata Interface Definition
@custom:contract-name IERC1155MetadataURI
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The metadata extension is optional for an ERC-1155
        smart contract. This allows a smart contract to
        be interrogated for the Uniform Resource Identifier
        (URI) details of a specific token type. For more
        details, please refer to:
        https://eips.ethereum.org/EIPS/eip-1155#metadata.

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


# @dev We import the `IERC1155` interface, which is written
# using standard Vyper syntax, to highlight the association
# of the custom `IERC1155MetadataURI` interface with the custom
# `IERC1155` interface.
# @notice The interface `IERC1155MetadataURI` must be used in
# conjunction with the custom interface `IERC1155` to be EIP-1155
# compatible. If you want to use this interface as a stand-alone
# interface, you must add `implements: IERC1155` to this interface
# and implement all required events and functions accordingly.
import IERC1155 as IERC1155


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
def uri(_id: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for token type `_id`.
    @notice If the `{id}` substring is present in the URI,
            it must be replaced by clients with the actual
            token type ID. Note that the `uri` function must
            not be used to check for the existence of a token
            as it is possible for an implementation to return
            a valid string even if the token does not exist.
    @param _id The 32-byte identifier of the token type `_id`.
    @return String The maximum 512-character user-readable
            string token URI of the token type `_id`.
    """
    return empty(String[512])
