# @version ^0.3.7
"""
@title EIP-721 Optional Enumeration Interface Definition
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice The enumeration extension is optional for an ERC-721
        smart contract. This allows a contract to publish its
        full list of ERC-721 tokens and make them discoverable.
        For more details, please refer to:
        https://eips.ethereum.org/EIPS/eip-721#specification.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


@external
@view
def totalSupply() -> uint256:
    """
    @dev Returns the amount of tokens in existence.
    @return uint256 The 32-byte token supply.
    """
    return empty(uint256)


@external
@view
def tokenByIndex(_index: uint256) -> uint256:
    """
    @dev Returns a token ID at a given `_index` of
         all the tokens stored by the contract.
    @notice Use along with `totalSupply` to enumerate
            all tokens.
    @param _index The 32-byte counter (must be less
           than `totalSupply()`).
    @return uint256 The 32-byte token ID at index
            `_index`.
    """
    return empty(uint256)


@external
@view
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
    """
    @dev Returns a token ID owned by `_owner` at a
         given `_index` of its token list.
    @notice Use along with `balanceOf` to enumerate
            all of `_owner`'s tokens.
    @param _owner The 20-byte owner address.
    @param _index The 32-byte counter (must be less
           than `balanceOf(_owner)`).
    @return uint256 The 32-byte token ID owned by
            `_owner` at index `_index`.
    """
    return empty(uint256)
