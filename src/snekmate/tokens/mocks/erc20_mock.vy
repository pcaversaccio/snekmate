# pragma version ~=0.4.2
# pragma nonreentrancy off
"""
@title `erc20` Module Reference Implementation
@custom:contract-name erc20_mock
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


# @dev We import and initialise the `ownable` module.
from ...auth import ownable as ow
initializes: ow


# @dev We import and initialise the `erc20` module.
from .. import erc20
initializes: erc20[ownable := ow]


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `erc20` module. The built-in dunder method
# `__interface__` allows you to export all functions of a
# module without specifying the individual functions (see
# https://github.com/vyperlang/vyper/pull/3919). Please take
# note that if you do not know the full interface of a module
# contract, you can get the `.vyi` interface in Vyper by using
# `vyper -f interface your_filename.vy` or the external interface
# by using `vyper -f external_interface your_filename.vy`.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: erc20.__interface__


# @dev The following two parameters are required for the Echidna
# fuzzing test integration: https://github.com/crytic/properties.
isMintableOrBurnable: public(constant(bool)) = True
initialSupply: public(uint256)


@deploy
@payable
def __init__(
    name_: String[25],
    symbol_: String[5],
    decimals_: uint8,
    initial_supply_: uint256,
    name_eip712_: String[50],
    version_eip712_: String[20],
):
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
    @param initial_supply_ The 32-byte non-decimalised initial
           supply of the token.
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

    # We assign the initial token supply required by
    # the Echidna external harness contract.
    self.initialSupply = erc20.totalSupply


# @dev Duplicate implementation of the `external` function
# `burn_from` to enable the Echidna tests for the external
# burnable properties.
@external
def burnFrom(owner: address, amount: uint256):
    """
    @dev Destroys `amount` tokens from `owner`,
         deducting from the caller's allowance.
    @notice Note that `owner` cannot be the
            zero address. Also, the caller must
            have an allowance for `owner`'s tokens
            of at least `amount`.
    @param owner The 20-byte owner address.
    @param amount The 32-byte token amount to be destroyed.
    """
    erc20._spend_allowance(owner, msg.sender, amount)
    erc20._burn(owner, amount)
