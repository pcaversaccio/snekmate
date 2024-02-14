# pragma version ^0.3.10
"""
@title AccessControl Interface Definition
@custom:contract-name IAccessControl
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The interface definition of `AccessControl`
        to support the ERC-165 detection. In order
        to ensure consistency and interoperability,
        we follow OpenZeppelin's definition here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/IAccessControl.sol.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


# @dev Emitted when `newAdminRole` is set as
# `role`'s admin role, replacing `previousAdminRole`.
# Note that `DEFAULT_ADMIN_ROLE` is the starting
# admin for all roles, despite `RoleAdminChanged`
# not being emitted signaling this.
event RoleAdminChanged:
    role: indexed(bytes32)
    previousAdminRole: indexed(bytes32)
    newAdminRole: indexed(bytes32)


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
@view
def hasRole(role: bytes32, account: address) -> bool:
    """
    @dev Returns `True` if `account` has been
         granted `role`.
    @param role The 32-byte role definition.
    @param account The 20-byte address of the account.
    @return bool The verification whether the role
            `role` has been granted to `account` or not.
    """
    return empty(bool)


@external
@view
def getRoleAdmin(role: bytes32) -> bytes32:
    """
    @dev Returns the admin role that controls
         `role`.
    @notice See `grantRole` and `revokeRole`.
            To change a role's admin, use
            {AccessControl-set_role_admin}.
    @param role The 32-byte role definition.
    @return bytes32 The 32-byte admin role
            that controls `role`.
    """
    return empty(bytes32)


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
    pass


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
    pass


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
    pass
