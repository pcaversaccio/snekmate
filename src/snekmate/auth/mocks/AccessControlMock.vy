# pragma version ~=0.4.0b5
"""
@title Wrapper Contract for Multi-Role-Based Access Control Functions
@custom:contract-name AccessControlMock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and initialise the `AccessControl` module.
from .. import AccessControl as ac
initializes: ac


# @dev We import and implement the `IERC165` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC165
implements: IERC165


# @dev We import and implement the `IAccessControl`
# interface, which is written using standard Vyper
# syntax.
from ..interfaces import IAccessControl
implements: IAccessControl


# @dev An additional 32-byte access role.
ADDITIONAL_ROLE_1: public(constant(bytes32)) = keccak256("ADDITIONAL_ROLE_1")


# @dev An additional 32-byte access role.
ADDITIONAL_ROLE_2: public(constant(bytes32)) = keccak256("ADDITIONAL_ROLE_2")


# @dev We export all public functions from the `AccessControl` module.
# @notice It's important to also export public `immutable` and state
# variables.
exports: (
    ac.supportsInterface,
    ac.DEFAULT_ADMIN_ROLE,
    ac.hasRole,
    ac.getRoleAdmin,
    ac.grantRole,
    ac.revokeRole,
    ac.renounceRole,
    ac.set_role_admin
)


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
    ac.__init__() # Assigns the `DEFAULT_ADMIN_ROLE` to the `msg.sender`.
    ac._grant_role(ADDITIONAL_ROLE_1, msg.sender)
    ac._grant_role(ADDITIONAL_ROLE_2, msg.sender)
