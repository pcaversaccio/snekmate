# pragma version ~=0.4.0rc2
"""
@title ERC20 Module Reference Implementation
@custom:contract-name ERC20Mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and implement the `IERC20` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC20
implements: IERC20


# @dev We import and implement the `IERC20Detailed` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC20Detailed
implements: IERC20Detailed


# @dev We import and implement the `IERC20Permit`
# interface, which is written using standard Vyper
# syntax.
from ..interfaces import IERC20Permit
implements: IERC20Permit


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ...utils.interfaces import IERC5267
implements: IERC5267


# @dev We import and initialise the `Ownable` module.
from ...auth import Ownable as ow
initializes: ow


# @dev We import and initialise the `ERC20` module.
from .. import ERC20 as erc20
initializes: erc20[ownable := ow]


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `ERC20` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: (
    erc20.owner,
    erc20.transfer_ownership,
    erc20.renounce_ownership,
    erc20.totalSupply,
    erc20.balanceOf,
    erc20.transfer,
    erc20.allowance,
    erc20.approve,
    erc20.transferFrom,
    erc20.name,
    erc20.symbol,
    erc20.decimals,
    erc20.permit,
    erc20.nonces,
    erc20.DOMAIN_SEPARATOR,
    erc20.eip712Domain,
    erc20.burn,
    erc20.burn_from,
    erc20.is_minter,
    erc20.mint,
    erc20.set_minter,
)


@deploy
@payable
def __init__(name_: String[25], symbol_: String[5], decimals_: uint8, initial_supply_: uint256, name_eip712_: String[50], version_eip712_: String[20]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice The initial supply of the token as well
            as the `owner` role will be assigned to
            the `msg.sender`.
    @param name_ The maximum 25-character user-readable
           string name of the token.
    @param symbol_ The maximum 5-character user-readable
           string symbol of the token.
    @param decimals_ The 1-byte decimal places of the token.
    @param initial_supply_ The initial supply of the token.
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
    erc20.__init__(name_, symbol_, decimals_, name_eip712_, version_eip712_)

    # The following line premints an initial token
    # supply to the `msg.sender`, which takes the
    # underlying `decimals` value into account.
    erc20._mint(msg.sender, initial_supply_ * 10 ** convert(decimals_, uint256))
