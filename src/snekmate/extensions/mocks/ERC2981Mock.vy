# pragma version ~=0.4.0rc2
"""
@title ERC2981 Module Reference Implementation
@custom:contract-name ERC2981Mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and implement the `IERC165` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC165
implements: IERC165


# @dev We import and implement the `IERC2981` interface,
# which is written using standard Vyper syntax.
from ..interfaces import IERC2981
implements: IERC2981


# @dev We import and initialise the `Ownable` module.
from ...auth import Ownable as ow
initializes: ow


# @dev We import and initialise the `ERC2981` module.
from .. import ERC2981 as erc2981
initializes: erc2981[ownable := ow]


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `ERC2981` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: (
    # @notice If you are integrating this contract with an
    # ERC-721 or ERC-1155 contract, please ensure you include
    # the additional ERC-165 interface identifiers into the
    # function `supportsInterface`. One way to achieve this
    # would be to not export the `supportsInterface` function
    # from {ERC2981} in the main contract and implement the
    # following function in the main contract instead:
    # ```vy
    # @external
    # @view
    # def supportsInterface(interface_id: bytes4) -> bool:
    #     return (interface_id in erc2981._SUPPORTED_INTERFACES) or (interface_id in [0x..., ...])
    # ```
    erc2981.supportsInterface,
    erc2981.owner,
    # @notice If you integrate the function `transfer_ownership`
    # into an ERC-721 or ERC-1155 contract that implements an
    # `is_minter` role, ensure that the previous owner's minter
    # role is also removed and the minter role is assigned to the
    # `new_owner` accordingly.
    erc2981.transfer_ownership,
    # @notice If you integrate the function `renounce_ownership`
    # into an ERC-721 or ERC-1155 contract that implements an
    # `is_minter` role, ensure that the previous owner's minter
    # role as well as all non-owner minter addresses are also
    # removed before calling `renounce_ownership`.
    erc2981.renounce_ownership,
    erc2981.royaltyInfo,
    erc2981.set_default_royalty,
    erc2981.delete_default_royalty,
    erc2981.set_token_royalty,
    erc2981.reset_token_royalty,
)


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice The `owner` role will be assigned to the
            `msg.sender`. Furthermore, the default value
            of {ERC2981-_fee_denominator} is set to `10_000`.
    """
    # The following line assigns the `owner`
    # to the `msg.sender`.
    ow.__init__()
    # The following line sets the default value
    # of {ERC2981-_fee_denominator} to `10_000`
    # so that the fee is in basis points by default.
    erc2981.__init__()
