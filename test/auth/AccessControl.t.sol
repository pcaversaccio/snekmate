// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {InvariantTest} from "forge-std/InvariantTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";

import {IAccessControlExtended} from "./interfaces/IAccessControlExtended.sol";

contract AccessControlTest is Test {
    bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0);
    bytes32 public constant ADDITIONAL_ROLE_1 = keccak256("ADDITIONAL_ROLE_1");
    bytes32 public constant ADDITIONAL_ROLE_2 = keccak256("ADDITIONAL_ROLE_2");

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IAccessControlExtended private accessControl;
    IAccessControlExtended private accessControlInitialEvent;

    address private deployer = address(vyperDeployer);

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
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, deployer));
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, deployer));
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_2, deployer));
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

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(DEFAULT_ADMIN_ROLE, deployer, deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, deployer, deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_2, deployer, deployer);
        accessControlInitialEvent = IAccessControlExtended(
            vyperDeployer.deployContract("src/auth/", "AccessControl")
        );
        assertTrue(
            accessControlInitialEvent.hasRole(DEFAULT_ADMIN_ROLE, deployer)
        );
        assertTrue(
            accessControlInitialEvent.hasRole(ADDITIONAL_ROLE_1, deployer)
        );
        assertTrue(
            accessControlInitialEvent.hasRole(ADDITIONAL_ROLE_2, deployer)
        );
        assertEq(
            accessControlInitialEvent.getRoleAdmin(DEFAULT_ADMIN_ROLE),
            DEFAULT_ADMIN_ROLE
        );
        assertEq(
            accessControlInitialEvent.getRoleAdmin(ADDITIONAL_ROLE_1),
            DEFAULT_ADMIN_ROLE
        );
        assertEq(
            accessControlInitialEvent.getRoleAdmin(ADDITIONAL_ROLE_2),
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

    function testGrantRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testGrantRoleAdminRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(DEFAULT_ADMIN_ROLE, account, admin);
        accessControl.grantRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        vm.stopPrank();
    }

    function testGrantRoleMultipleTimesSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testGrantRoleNonAdmin() public {
        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.grantRole(ADDITIONAL_ROLE_1, makeAddr("account"));
    }

    function testRevokeRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, admin);
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testRevokeRoleMultipleTimesSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, admin);
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testRevokeRoleAdminRoleSuccess() public {
        address admin = deployer;
        vm.startPrank(admin);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));
        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(DEFAULT_ADMIN_ROLE, admin, admin);
        accessControl.revokeRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));

        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.revokeRole(ADDITIONAL_ROLE_1, admin);
        vm.stopPrank();
    }

    function testRevokeRoleNonAdmin() public {
        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.revokeRole(ADDITIONAL_ROLE_1, makeAddr("account"));
    }

    function testRenounceRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, account);
        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testRenounceRoleMultipleTimesSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, account);
        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testRenounceRoleAdminRoleSuccess() public {
        address admin = deployer;
        vm.startPrank(admin);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));
        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(DEFAULT_ADMIN_ROLE, admin, admin);
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));

        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));
        vm.stopPrank();
    }

    function testRenounceRoleNonMsgSender() public {
        vm.expectRevert(
            bytes("AccessControl: can only renounce roles for itself")
        );
        accessControl.renounceRole(ADDITIONAL_ROLE_1, makeAddr("account"));
    }

    function testSetRoleAdminSuccess() public {
        address admin = deployer;
        address otherAdmin = makeAddr("otherAdmin");
        address account = makeAddr("account");
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(
            ADDITIONAL_ROLE_1,
            DEFAULT_ADMIN_ROLE,
            otherAdminRole
        );
        accessControl.set_role_admin(ADDITIONAL_ROLE_1, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));
        vm.stopPrank();

        vm.startPrank(otherAdmin);
        assertEq(accessControl.getRoleAdmin(ADDITIONAL_ROLE_1), otherAdminRole);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, otherAdmin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, otherAdmin);
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testSetRoleAdminPreviousAdminCallsGrantRole() public {
        address admin = deployer;
        address otherAdmin = makeAddr("otherAdmin");
        address account = makeAddr("account");
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(
            ADDITIONAL_ROLE_1,
            DEFAULT_ADMIN_ROLE,
            otherAdminRole
        );
        accessControl.set_role_admin(ADDITIONAL_ROLE_1, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        vm.stopPrank();
    }

    function testSetRoleAdminPreviousAdminCallsRevokeRole() public {
        address admin = deployer;
        address otherAdmin = makeAddr("otherAdmin");
        address account = makeAddr("account");
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);

        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(
            ADDITIONAL_ROLE_1,
            DEFAULT_ADMIN_ROLE,
            otherAdminRole
        );
        accessControl.set_role_admin(ADDITIONAL_ROLE_1, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        vm.stopPrank();
    }

    function testFuzzGrantRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testFuzzGrantRoleAdminRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(DEFAULT_ADMIN_ROLE, account, admin);
        accessControl.grantRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzGrantRoleMultipleTimesSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testFuzzGrantRoleNonAdmin(
        address nonAdmin,
        address account
    ) public {
        vm.assume(nonAdmin != deployer);
        vm.prank(nonAdmin);
        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
    }

    function testFuzzRevokeRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, admin);
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testFuzzRevokeRoleMultipleTimesSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, admin);
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testFuzzRevokeRoleNonAdmin(
        address nonAdmin,
        address account
    ) public {
        vm.assume(nonAdmin != deployer);
        vm.prank(nonAdmin);
        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
    }

    function testFuzzRenounceRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, account);
        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testFuzzRenounceRoleMultipleTimesSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, account);
        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testFuzzRenounceRoleNonMsgSender(address account) public {
        vm.assume(address(this) != account);
        vm.expectRevert(
            bytes("AccessControl: can only renounce roles for itself")
        );
        accessControl.renounceRole(ADDITIONAL_ROLE_1, account);
    }

    function testFuzzSetRoleAdminSuccess(
        address otherAdmin,
        address account
    ) public {
        vm.assume(otherAdmin != deployer && account != deployer);
        address admin = deployer;
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(
            ADDITIONAL_ROLE_1,
            DEFAULT_ADMIN_ROLE,
            otherAdminRole
        );
        accessControl.set_role_admin(ADDITIONAL_ROLE_1, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));
        vm.stopPrank();

        vm.startPrank(otherAdmin);
        assertEq(accessControl.getRoleAdmin(ADDITIONAL_ROLE_1), otherAdminRole);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(ADDITIONAL_ROLE_1, account, otherAdmin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        assertTrue(accessControl.hasRole(ADDITIONAL_ROLE_1, account));

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADDITIONAL_ROLE_1, account, otherAdmin);
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        assertTrue(!accessControl.hasRole(ADDITIONAL_ROLE_1, account));
        vm.stopPrank();
    }

    function testFuzzSetRoleAdminPreviousAdminCallsGrantRole(
        address otherAdmin,
        address account
    ) public {
        vm.assume(otherAdmin != deployer);
        address admin = deployer;
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(
            ADDITIONAL_ROLE_1,
            DEFAULT_ADMIN_ROLE,
            otherAdminRole
        );
        accessControl.set_role_admin(ADDITIONAL_ROLE_1, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);
        vm.stopPrank();
    }

    function testFuzzSetRoleAdminPreviousAdminCallsRevokeRole(
        address otherAdmin,
        address account
    ) public {
        vm.assume(otherAdmin != deployer);
        address admin = deployer;
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        accessControl.grantRole(ADDITIONAL_ROLE_1, account);

        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(
            ADDITIONAL_ROLE_1,
            DEFAULT_ADMIN_ROLE,
            otherAdminRole
        );
        accessControl.set_role_admin(ADDITIONAL_ROLE_1, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("AccessControl: account is missing role"));
        accessControl.revokeRole(ADDITIONAL_ROLE_1, account);
        vm.stopPrank();
    }
}
