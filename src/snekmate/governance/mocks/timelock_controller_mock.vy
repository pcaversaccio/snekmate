# pragma version ~=0.4.1b3
"""
@title `timelock_controller` Module Reference Implementation
@custom:contract-name timelock_controller_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and implement the `IERC165` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC165
implements: IERC165


# @dev We import and implement the `IAccessControl`
# interface, which is written using standard Vyper
# syntax.
from ...auth.interfaces import IAccessControl
implements: IAccessControl


# @dev We import and implement the `IERC721Receiver`
# interface, which is written using standard Vyper
# syntax.
from ...tokens.interfaces import IERC721Receiver
implements: IERC721Receiver


# @dev We import and implement the `IERC1155Receiver`
# interface, which is written using standard Vyper
# syntax.
from ...tokens.interfaces import IERC1155Receiver
implements: IERC1155Receiver


# @dev We import and initialise the `access_control` module.
from ...auth import access_control as ac
initializes: ac


# @dev We import and initialise the `timelock_controller` module.
from .. import timelock_controller as tc
initializes: tc[access_control := ac]


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `timelock_controller` module. The built-in dunder
# method `__interface__` allows you to export all functions
# of a module without specifying the individual functions (see
# https://github.com/vyperlang/vyper/pull/3919). Please take
# note that if you do not know the full interface of a module
# contract, you can get the `.vyi` interface in Vyper by using
# `vyper -f interface your_filename.vy` or the external interface
# by using `vyper -f external_interface your_filename.vy`.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: tc.__interface__


@deploy
@payable
def __init__(
    minimum_delay_: uint256,
    proposers_: DynArray[address, tc._DYNARRAY_BOUND],
    executors_: DynArray[address, tc._DYNARRAY_BOUND],
    admin_: address,
):
    """
    @dev Initialises the contract with the following parameters:
           - `minimum_delay_`: The initial minimum delay in seconds
              for operations,
           - `proposers_`: The accounts to be granted proposer and
              canceller roles,
           - `executors_`: The accounts to be granted executor role,
           - `admin_`: The optional account to be granted admin role
              (disable with the zero address).

         IMPORTANT: The optional admin can aid with initial
         configuration of roles after deployment without being
         subject to delay, but this role should be subsequently
         renounced in favor of administration through timelocked
         proposals.

         To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @param minimum_delay_ The 32-byte minimum delay in seconds
           for operations.
    @param proposers_ The 20-byte array of accounts to be granted
           proposer and canceller roles.
    @param executors_ The 20-byte array of accounts to be granted
           executor role.
    @param admin_ The 20-byte (optional) account to be granted admin
           role.
    """
    # The following line assigns the `DEFAULT_ADMIN_ROLE`
    # to the `msg.sender`.
    ac.__init__()
    # The following line revokes the `DEFAULT_ADMIN_ROLE`
    # from the `msg.sender`.
    tc.__init__(minimum_delay_, proposers_, executors_, admin_)
