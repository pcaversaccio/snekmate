# pragma version ^0.3.10
"""
@title Multi-Role-Based Access Control Functions
@custom:contract-name AccessControl
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to implement role-based access
        control mechanisms. Roles are referred to by their `bytes32`
        identifier. These should be exposed in the external API and
        be unique. The best way to achieve this is by using `public
        constant` hash digests:
        ```vy
        MY_ROLE: public(constant(bytes32)) = keccak256("MY_ROLE");
        ```

        Roles can be used to represent a set of permissions. To restrict
        access to a function call, use the `external` function `hasRole`
        or the `internal` function `_check_role` (to avoid any NatSpec
        parsing error, no `@` character is added to the visibility decorator
        `@external` in the following examples; please add them accordingly):
        ```vy
        external
        def foo():
            assert self.hasRole[MY_ROLE][msg.sender], "AccessControl: account is missing role"
            ...

        OR

        external
        def foo():
            self._check_role(MY_ROLE, msg.sender)
            ...
        ```

        Roles can be granted and revoked dynamically via the `grantRole`
        and `revokeRole` functions. Each role has an associated admin role,
        and only accounts that have a role's admin role can call `grantRole`
        and `revokeRole`. Also, by default, the admin role for all roles is
        `DEFAULT_ADMIN_ROLE`, which means that only accounts with this role
        will be able to grant or revoke other roles. More complex role
        relationships can be created by using `set_role_admin`.

        WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin! It has
        permission to grant and revoke this role. Extra precautions should be
        taken to secure accounts that have been granted it.

        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `IAccessControl`
# interface, which is written using standard Vyper
# syntax.
import interfaces.IAccessControl as IAccessControl
implements: IAccessControl


# @dev The default 32-byte admin role.
DEFAULT_ADMIN_ROLE: public(constant(bytes32)) = empty(bytes32)


# @dev An additional 32-byte access role.
# @notice Please adjust the naming of the variable
# according to your specific requirement,
# e.g. `MINTER_ROLE`.
ADDITIONAL_ROLE_1: public(constant(bytes32)) = keccak256("ADDITIONAL_ROLE_1")


# @dev An additional 32-byte access role.
# @notice Please adjust the naming of the variable
# according to your specific requirement,
# e.g. `PAUSER_ROLE`. Also, feel free to add more
# roles if necessary. In this case, it is important
# to extend the constructor accordingly.
ADDITIONAL_ROLE_2: public(constant(bytes32)) = keccak256("ADDITIONAL_ROLE_2")


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0x7965DB0B, # The ERC-165 identifier for `IAccessControl`.
]


# @dev Returns `True` if `account` has been granted `role`.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable.
hasRole: public(HashMap[bytes32, HashMap[address, bool]])


# @dev Returns the admin role that controls `role`.
getRoleAdmin: public(HashMap[bytes32, bytes32])


# @dev Emitted when `new_admin_role` is set as
# `role`'s admin role, replacing `previous_admin_role`.
# Note that `DEFAULT_ADMIN_ROLE` is the starting
# admin for all roles, despite `RoleAdminChanged`
# not being emitted signaling this.
event RoleAdminChanged:
    role: indexed(bytes32)
    previous_admin_role: indexed(bytes32)
    new_admin_role: indexed(bytes32)


# @dev Emitted when `account` is granted `role`.
# Note that `sender` is the account (an admin
# role bearer) that originated the contract call.
event RoleGranted:
    role: indexed(bytes32)
    account: indexed(address)
    sender: indexed(address)


# @dev Emitted when `account` is revoked `role`.
# Note that `sender` is the account that originated
# the contract call:
#   - if using `revokeRole`, it is the admin role
#     bearer,
#   - if using `renounceRole`, it is the role bearer
#     (i.e. `account`).
event RoleRevoked:
    role: indexed(bytes32)
    account: indexed(address)
    sender: indexed(address)


@external
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice All predefined roles will be assigned to
            the `msg.sender`.
    """
    self._grant_role(DEFAULT_ADMIN_ROLE, msg.sender)
    self._grant_role(ADDITIONAL_ROLE_1, msg.sender)
    self._grant_role(ADDITIONAL_ROLE_2, msg.sender)


@external
@view
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interface_id`.
    @param interface_id The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return interface_id in _SUPPORTED_INTERFACES


@external
def grantRole(role: bytes32, account: address):
    """
    @dev Grants `role` to `account`.
    @notice If `account` had not been already
            granted `role`, emits a `RoleGranted`
            event. Note that the caller must have
            `role`'s admin role.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._grant_role(role, account)


@external
def revokeRole(role: bytes32, account: address):
    """
    @dev Revokes `role` from `account`.
    @notice If `account` had been granted `role`,
            emits a `RoleRevoked` event. Note that
            the caller must have `role`'s admin role.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._revoke_role(role, account)


@external
def renounceRole(role: bytes32, account: address):
    """
    @dev Revokes `role` from the calling account.
    @notice Roles are often managed via `grantRole`
            and `revokeRole`. This function's purpose
            is to provide a mechanism for accounts to
            lose their privileges if they are compromised
            (such as when a trusted device is misplaced).
            If the calling account had been granted `role`,
            emits a `RoleRevoked` event. Note that the
            caller must be `account`.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    assert account == msg.sender, "AccessControl: can only renounce roles for itself"
    self._revoke_role(role, account)


@external
def set_role_admin(role: bytes32, admin_role: bytes32):
    """
    @dev Sets `admin_role` as `role`'s admin role.
    @notice Note that the caller must have `role`'s
            admin role.
    @param role The 32-byte role definition.
    @param admin_role The new 32-byte admin role definition.
    """
    self._check_role(self.getRoleAdmin[role], msg.sender)
    self._set_role_admin(role, admin_role)


@internal
def _check_role(role: bytes32, account: address):
    """
    @dev Reverts with a standard message if `account`
         is missing `role`.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    assert self.hasRole[role][account], "AccessControl: account is missing role"


@internal
def _set_role_admin(role: bytes32, admin_role: bytes32):
    """
    @dev Sets `admin_role` as `role`'s admin role.
    @notice This is an `internal` function without
            access restriction.
    @param role The 32-byte role definition.
    @param admin_role The new 32-byte admin role definition.
    """
    previous_admin_role: bytes32 = self.getRoleAdmin[role]
    self.getRoleAdmin[role] = admin_role
    log RoleAdminChanged(role, previous_admin_role, admin_role)


@internal
def _grant_role(role: bytes32, account: address):
    """
    @dev Grants `role` to `account`.
    @notice This is an `internal` function without
            access restriction.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    if (not(self.hasRole[role][account])):
        self.hasRole[role][account] = True
        log RoleGranted(role, account, msg.sender)


@internal
def _revoke_role(role: bytes32, account: address):
    """
    @dev Revokes `role` from `account`.
    @notice This is an `internal` function without
            access restriction.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    """
    if (self.hasRole[role][account]):
        self.hasRole[role][account] = False
        log RoleRevoked(role, account, msg.sender)
