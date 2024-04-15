# pragma version ~=0.4.0rc2
"""
@title AccessControl Module Reference Implementation
@custom:contract-name AccessControlMock
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
from ..interfaces import IAccessControl
implements: IAccessControl


# @dev We import and initialise the `AccessControl` module.
from .. import AccessControl as ac
initializes: ac


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) all `external` functions
# from the `AccessControl` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: ac.__interface__


# @dev The 32-byte minter role.
MINTER_ROLE: public(constant(bytes32)) = keccak256("MINTER_ROLE")


# @dev The 32-byte pauser role.
PAUSER_ROLE: public(constant(bytes32)) = keccak256("PAUSER_ROLE")


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice All predefined roles will be assigned to
            the `msg.sender`.
    """
    # The following line assigns the `DEFAULT_ADMIN_ROLE`
    # to the `msg.sender`.
    ac.__init__()
    ac._grant_role(MINTER_ROLE, msg.sender)
    ac._grant_role(PAUSER_ROLE, msg.sender)
