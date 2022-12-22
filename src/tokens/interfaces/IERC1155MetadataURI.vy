# @version ^0.3.7
"""
@title EIP-1155 Optional Metadata Interface Definition
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice The metadata extension is optional for an ERC-1155
        smart contract. This allows a smart contract to
        be interrogated for the Uniform Resource Identifier
        (URI) details of a specific token type. For more
        details, please refer to:
        https://eips.ethereum.org/EIPS/eip-1155.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


@external
@view
def uri(_id: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for token type `_id`.
    @notice If the `_id` substring is present in the URI,
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
