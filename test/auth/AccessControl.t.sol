// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";

import {IAccessControlExtended} from "./interfaces/IAccessControlExtended.sol";

contract AccessControlTest is Test {
    bytes32 public constant DEFAULT_ADMIN_ROLE =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant ADDITIONAL_ROLE_1 = keccak256("ADDITIONAL_ROLE_1");
    bytes32 public constant ADDITIONAL_ROLE_2 = keccak256("ADDITIONAL_ROLE_2");

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IAccessControlExtended private accessControl;

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function setUp() public {
        accessControl = IAccessControlExtended(
            vyperDeployer.deployContract("src/auth/", "AccessControl")
        );
    }

    function testInitialSetup() public {
        address account = address(vyperDeployer);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_2, account));
        assertEq(
            accessControl.getRoleAdmin(DEFAULT_ADMIN_ROLE),
            DEFAULT_ADMIN_ROLE
        );
        assertEq(
            accessControl.getRoleAdmin(ADDITIONAL_ROLE_1),
            DEFAULT_ADMIN_ROLE
        );
        assertEq(
            accessControl.getRoleAdmin(ADDITIONAL_ROLE_2),
            DEFAULT_ADMIN_ROLE
        );
    }

    function testSupportsInterfaceSuccess() public {
        assertTrue(accessControl.supportsInterface(type(IERC165).interfaceId));
        assertTrue(
            accessControl.supportsInterface(type(IAccessControl).interfaceId)
        );
    }

    function testSupportsInterfaceGasCost() public {
        uint256 startGas = gasleft();
        accessControl.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(gasUsed < 30_000);
    }

    function testSupportsInterfaceInvalidInterfaceId() public {
        assertTrue(!accessControl.supportsInterface(0x0011bbff));
    }
}
