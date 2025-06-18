# pragma version ~=0.4.3rc2
# pragma nonreentrancy off
"""
@title `erc4626` Module Reference Implementation
@custom:contract-name erc4626_mock
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
from ...tokens.interfaces import IERC20Permit
implements: IERC20Permit


# @dev We import and implement the `IERC4626` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC4626
implements: IERC4626


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ...utils.interfaces import IERC5267
implements: IERC5267


# @dev We import and initialise the `erc4626` module.
from .. import erc4626
initializes: erc4626


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `erc4626` module. The built-in dunder method
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
exports: erc4626.__interface__


@deploy
@payable
def __init__(
    name_: String[25],
    symbol_: String[5],
    asset_: IERC20,
    decimals_offset_: uint8,
    name_eip712_: String[50],
    version_eip712_: String[20],
):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @param name_ The maximum 25-character user-readable
           string name of the token.
    @param symbol_ The maximum 5-character user-readable
           string symbol of the token.
    @param asset_ The ERC-20 compatible (i.e. ERC-777 is also viable)
           underlying asset contract.
    @param decimals_offset_ The 1-byte offset in the decimal
           representation between the underlying asset's
           decimals and the vault decimals. The recommended value to
           mitigate the risk of an inflation attack is `0`.
    @param name_eip712_ The maximum 50-character user-readable
           string name of the signing domain, i.e. the name
           of the dApp or protocol.
    @param version_eip712_ The maximum 20-character current
           main version of the signing domain. Signatures
           from different versions are not compatible.
    """
    erc4626.__init__(name_, symbol_, asset_, decimals_offset_, name_eip712_, version_eip712_)
