# pragma version ~=0.4.0rc2
"""
@title `erc1155` Module Reference Implementation
@custom:contract-name erc1155_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and implement the `IERC165` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC165
implements: IERC165


# @dev We import and implement the `IERC1155` interface,
# which is written using standard Vyper syntax.
from ..interfaces import IERC1155
implements: IERC1155


# @dev We import and implement the `IERC1155MetadataURI`
# interface, which is written using standard Vyper
# syntax.
from ..interfaces import IERC1155MetadataURI
implements: IERC1155MetadataURI


# @dev We import and initialise the `ownable` module.
from ...auth import ownable as ow
initializes: ow


# @dev We import and initialise the `erc1155` module.
from .. import erc1155
initializes: erc1155[ownable := ow]


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `erc1155` module. The built-in dunder method
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
# the {erc1155} contract, please ensure you exclude the unused
# ERC-165 interface identifiers in the main contract. One way
# to achieve this would be to not export the `supportsInterface`
# function from {erc1155} in the main contract and implement the
# following function in the main contract instead:
# ```vy
# _SUPPORTED_INTERFACES: constant(bytes4[...]) = [
#     erc1155._SUPPORTED_INTERFACES[0], # The ERC-165 identifier for ERC-165.
#     erc1155._SUPPORTED_INTERFACES[1], # The ERC-165 identifier for ERC-1155.
#     ...                              # Any further ERC-165 identifiers you require.
# ]
#
#
# @external
# @view
# def supportsInterface(interface_id: bytes4) -> bool:
#     return interface_id in _SUPPORTED_INTERFACES
# ```
exports: erc1155.__interface__


@deploy
@payable
def __init__(base_uri_: String[80]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice The `owner` role will be assigned to
            the `msg.sender`.
    @param base_uri_ The maximum 80-character user-readable
           string base URI for computing `uri`.
    """
    # The following line assigns the `owner`
    # to the `msg.sender`.
    ow.__init__()
    erc1155.__init__(base_uri_)
