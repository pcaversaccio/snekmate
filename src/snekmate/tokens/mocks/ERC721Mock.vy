# pragma version ~=0.4.0rc2
"""
@title ERC721 Module Reference Implementation
@custom:contract-name ERC721Mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and implement the `IERC165` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC165
implements: IERC165


# @dev We import and implement the `IERC721` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC721
implements: IERC721


# @dev We import and implement the `IERC721Metadata`
# interface, which is written using standard Vyper
# syntax.
from ..interfaces import IERC721Metadata
implements: IERC721Metadata


# @dev We import and implement the `IERC721Enumerable`
# interface, which is written using standard Vyper
# syntax.
from ..interfaces import IERC721Enumerable
implements: IERC721Enumerable


# @dev We import and implement the `IERC721Permit`
# interface, which is written using standard Vyper
# syntax.
from ..interfaces import IERC721Permit
implements: IERC721Permit


# @dev We import and implement the `IERC4906` interface,
# which is written using standard Vyper syntax.
from ..interfaces import IERC4906
implements: IERC4906


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ...utils.interfaces import IERC5267
implements: IERC5267


# @dev We import and initialise the `Ownable` module.
from ...auth import Ownable as ow
initializes: ow


# @dev We import and initialise the `ERC721` module.
from .. import ERC721 as erc721
initializes: erc721[ownable := ow]


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `ERC721` module. The built-in dunder method
# `__interface__` allows you to export all functions of a
# module without specifying the individual functions (see
# https://github.com/vyperlang/vyper/pull/3919). Please take
# note that if you do not know the full interface of a module
# contract, you can get the `.vyi` interface in Vyper by using
# `vyper -f interface yourFileName.vy` or the external interface
# by using `vyper -f external_interface yourFileName.vy`.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
# Furthermore, if you are not using the full feature set of
# the {ERC721} contract, please ensure you exclude the unused
# ERC-165 interface identifiers in the main contract. One way
# to achieve this would be to not export the `supportsInterface`
# function from {ERC721} in the main contract and implement the
# following function in the main contract instead:
# ```vy
# _SUPPORTED_INTERFACES: constant(bytes4[...]) = [
#     erc721._SUPPORTED_INTERFACES[0], # The ERC-165 identifier for ERC-165.
#     erc721._SUPPORTED_INTERFACES[1], # The ERC-165 identifier for ERC-721.
#     ...                              # Any further ERC-165 identifiers you require.
# ]
#
#
# @external
# @view
# def supportsInterface(interface_id: bytes4) -> bool:
#     return interface_id in _SUPPORTED_INTERFACES
# ```
exports: erc721.__interface__


# @dev The following two parameters are required for the Echidna
# fuzzing test integration: https://github.com/crytic/properties.
isMintableOrBurnable: public(constant(bool)) = True
usedId: public(HashMap[uint256, bool])


@deploy
@payable
def __init__(name_: String[25], symbol_: String[5], base_uri_: String[80], name_eip712_: String[50], version_eip712_: String[20]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice The `owner` role will be assigned to
            the `msg.sender`.
    @param name_ The maximum 25-character user-readable string
           name of the token collection.
    @param symbol_ The maximum 5-character user-readable string
           symbol of the token collection.
    @param base_uri_ The maximum 80-character user-readable
           string base URI for computing `tokenURI`.
    @param name_eip712_ The maximum 50-character user-readable
           string name of the signing domain, i.e. the name
           of the dApp or protocol.
    @param version_eip712_ The maximum 20-character current
           main version of the signing domain. Signatures
           from different versions are not compatible.
    """
    # The following line assigns the `owner`
    # to the `msg.sender`.
    ow.__init__()
    erc721.__init__(name_, symbol_, base_uri_, name_eip712_, version_eip712_)


# @dev Custom implementation of the `external` function `safe_mint`
# without access restriction and {IERC721Receiver-onERC721Received}
# check to enable the Echidna tests for the external mintable properties.
@external
def _customMint(owner: address, amount: uint256):
    """
    @dev Creates `amount` tokens and assigns them to
         `owner`, increasing the total supply.
    @notice Note that each `token_id` must not exist
            and `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @param amount The 32-byte token amount to be created.
    """
    for _: uint256 in range(amount, bound=64):
        token_id: uint256 = erc721._counter
        erc721._counter = token_id + 1
        erc721._mint(owner, token_id)
