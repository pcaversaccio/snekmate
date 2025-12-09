// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.31;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";

import {IAccessControlExtended} from "./interfaces/IAccessControlExtended.sol";

contract AccessControlTest is Test {
    bytes32 private constant DEFAULT_ADMIN_ROLE = bytes32(0);
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IAccessControlExtended private accessControl;
    IAccessControlExtended private accessControlInitialEvent;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        accessControl = IAccessControlExtended(
            vyperDeployer.deployContract("src/snekmate/auth/mocks/", "access_control_mock")
        );
    }

    function testInitialSetup() public {
        assertEq(accessControl.DEFAULT_ADMIN_ROLE(), DEFAULT_ADMIN_ROLE);
        assertEq(accessControl.MINTER_ROLE(), MINTER_ROLE);
        assertEq(accessControl.PAUSER_ROLE(), PAUSER_ROLE);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, deployer));
        assertTrue(accessControl.hasRole(MINTER_ROLE, deployer));
        assertTrue(accessControl.hasRole(PAUSER_ROLE, deployer));
        assertEq(accessControl.getRoleAdmin(DEFAULT_ADMIN_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(accessControl.getRoleAdmin(MINTER_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(accessControl.getRoleAdmin(PAUSER_ROLE), DEFAULT_ADMIN_ROLE);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(DEFAULT_ADMIN_ROLE, deployer, deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, deployer, deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(PAUSER_ROLE, deployer, deployer);
        accessControlInitialEvent = IAccessControlExtended(
            vyperDeployer.deployContract("src/snekmate/auth/mocks/", "access_control_mock")
        );
        assertEq(accessControlInitialEvent.DEFAULT_ADMIN_ROLE(), DEFAULT_ADMIN_ROLE);
        assertEq(accessControlInitialEvent.MINTER_ROLE(), MINTER_ROLE);
        assertEq(accessControlInitialEvent.PAUSER_ROLE(), PAUSER_ROLE);
        assertTrue(accessControlInitialEvent.hasRole(DEFAULT_ADMIN_ROLE, deployer));
        assertTrue(accessControlInitialEvent.hasRole(MINTER_ROLE, deployer));
        assertTrue(accessControlInitialEvent.hasRole(PAUSER_ROLE, deployer));
        assertEq(accessControlInitialEvent.getRoleAdmin(DEFAULT_ADMIN_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(accessControlInitialEvent.getRoleAdmin(MINTER_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(accessControlInitialEvent.getRoleAdmin(PAUSER_ROLE), DEFAULT_ADMIN_ROLE);
    }

    function testSupportsInterfaceSuccess() public view {
        assertTrue(accessControl.supportsInterface(type(IERC165).interfaceId));
        assertTrue(accessControl.supportsInterface(type(IAccessControl).interfaceId));
    }

    function testSupportsInterfaceSuccessGasCost() public view {
        uint256 startGas = gasleft();
        accessControl.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(gasUsed <= 30_000 && accessControl.supportsInterface(type(IERC165).interfaceId));
    }

    function testSupportsInterfaceInvalidInterfaceId() public view {
        assertTrue(!accessControl.supportsInterface(0x0011bbff));
    }

    function testSupportsInterfaceInvalidInterfaceIdGasCost() public view {
        uint256 startGas = gasleft();
        accessControl.supportsInterface(0x0011bbff);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(gasUsed <= 30_000 && !accessControl.supportsInterface(0x0011bbff));
    }

    function testGrantRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testGrantRoleAdminRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(DEFAULT_ADMIN_ROLE, account, admin);
        accessControl.grantRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        vm.stopPrank();
    }

    function testGrantRoleMultipleTimesSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testGrantRoleNonAdmin() public {
        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.grantRole(MINTER_ROLE, makeAddr("account"));
    }

    function testRevokeRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, admin);
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testRevokeRoleMultipleTimesSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, admin);
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testRevokeRoleAdminRoleSuccess() public {
        address admin = deployer;
        vm.startPrank(admin);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(DEFAULT_ADMIN_ROLE, admin, admin);
        accessControl.revokeRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));

        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.revokeRole(MINTER_ROLE, admin);
        vm.stopPrank();
    }

    function testRevokeRoleNonAdmin() public {
        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.revokeRole(MINTER_ROLE, makeAddr("account"));
    }

    function testRenounceRoleSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, account);
        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testRenounceRoleMultipleTimesSuccess() public {
        address admin = deployer;
        address account = makeAddr("account");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, account);
        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testRenounceRoleAdminRoleSuccess() public {
        address admin = deployer;
        vm.startPrank(admin);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(DEFAULT_ADMIN_ROLE, admin, admin);
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));

        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));
        vm.stopPrank();
    }

    function testRenounceRoleNonMsgSender() public {
        vm.expectRevert(bytes("access_control: can only renounce roles for itself"));
        accessControl.renounceRole(MINTER_ROLE, makeAddr("account"));
    }

    function testSetRoleAdminSuccess() public {
        address admin = deployer;
        address otherAdmin = makeAddr("otherAdmin");
        address account = makeAddr("account");
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(MINTER_ROLE, DEFAULT_ADMIN_ROLE, otherAdminRole);
        accessControl.set_role_admin(MINTER_ROLE, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));
        vm.stopPrank();

        vm.startPrank(otherAdmin);
        assertEq(accessControl.getRoleAdmin(MINTER_ROLE), otherAdminRole);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, otherAdmin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, otherAdmin);
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testSetRoleAdminPreviousAdminCallsGrantRole() public {
        address admin = deployer;
        address otherAdmin = makeAddr("otherAdmin");
        address account = makeAddr("account");
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(MINTER_ROLE, DEFAULT_ADMIN_ROLE, otherAdminRole);
        accessControl.set_role_admin(MINTER_ROLE, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.grantRole(MINTER_ROLE, account);
        vm.stopPrank();
    }

    function testSetRoleAdminPreviousAdminCallsRevokeRole() public {
        address admin = deployer;
        address otherAdmin = makeAddr("otherAdmin");
        address account = makeAddr("account");
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        accessControl.grantRole(MINTER_ROLE, account);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(MINTER_ROLE, DEFAULT_ADMIN_ROLE, otherAdminRole);
        accessControl.set_role_admin(MINTER_ROLE, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.revokeRole(MINTER_ROLE, account);
        vm.stopPrank();
    }

    function testFuzzGrantRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzGrantRoleAdminRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(DEFAULT_ADMIN_ROLE, account, admin);
        accessControl.grantRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzGrantRoleMultipleTimesSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzGrantRoleNonAdmin(address nonAdmin, address account) public {
        vm.assume(nonAdmin != deployer);
        vm.prank(nonAdmin);
        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.grantRole(MINTER_ROLE, account);
    }

    function testFuzzRevokeRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, admin);
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzRevokeRoleMultipleTimesSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, admin);
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzRevokeRoleNonAdmin(address nonAdmin, address account) public {
        vm.assume(nonAdmin != deployer);
        vm.prank(nonAdmin);
        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.revokeRole(MINTER_ROLE, account);
    }

    function testFuzzRenounceRoleSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, account);
        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzRenounceRoleMultipleTimesSuccess(address account) public {
        vm.assume(account != deployer);
        address admin = deployer;
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, admin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();

        vm.startPrank(account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));
        accessControl.renounceRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(!accessControl.hasRole(DEFAULT_ADMIN_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, account);
        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));

        accessControl.renounceRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzRenounceRoleNonMsgSender(address account) public {
        vm.assume(address(this) != account);
        vm.expectRevert(bytes("access_control: can only renounce roles for itself"));
        accessControl.renounceRole(MINTER_ROLE, account);
    }

    function testFuzzSetRoleAdminSuccess(address otherAdmin, address account) public {
        vm.assume(otherAdmin != deployer && account != deployer);
        address admin = deployer;
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(MINTER_ROLE, DEFAULT_ADMIN_ROLE, otherAdminRole);
        accessControl.set_role_admin(MINTER_ROLE, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));
        vm.stopPrank();

        vm.startPrank(otherAdmin);
        assertEq(accessControl.getRoleAdmin(MINTER_ROLE), otherAdminRole);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(MINTER_ROLE, account, otherAdmin);
        accessControl.grantRole(MINTER_ROLE, account);
        assertTrue(accessControl.hasRole(MINTER_ROLE, account));

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleRevoked(MINTER_ROLE, account, otherAdmin);
        accessControl.revokeRole(MINTER_ROLE, account);
        assertTrue(!accessControl.hasRole(MINTER_ROLE, account));
        vm.stopPrank();
    }

    function testFuzzSetRoleAdminPreviousAdminCallsGrantRole(address otherAdmin, address account) public {
        vm.assume(otherAdmin != deployer);
        address admin = deployer;
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(MINTER_ROLE, DEFAULT_ADMIN_ROLE, otherAdminRole);
        accessControl.set_role_admin(MINTER_ROLE, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.grantRole(MINTER_ROLE, account);
        vm.stopPrank();
    }

    function testFuzzSetRoleAdminPreviousAdminCallsRevokeRole(address otherAdmin, address account) public {
        vm.assume(otherAdmin != deployer);
        address admin = deployer;
        bytes32 otherAdminRole = keccak256("OTHER_ADMIN_ROLE");
        vm.startPrank(admin);
        accessControl.grantRole(MINTER_ROLE, account);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(MINTER_ROLE, DEFAULT_ADMIN_ROLE, otherAdminRole);
        accessControl.set_role_admin(MINTER_ROLE, otherAdminRole);

        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(otherAdminRole, otherAdmin, admin);
        accessControl.grantRole(otherAdminRole, otherAdmin);
        assertTrue(accessControl.hasRole(otherAdminRole, otherAdmin));

        vm.expectRevert(bytes("access_control: account is missing role"));
        accessControl.revokeRole(MINTER_ROLE, account);
        vm.stopPrank();
    }
}

contract AccessControlInvariants is Test {
    bytes32 private constant DEFAULT_ADMIN_ROLE = bytes32(0);
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IAccessControlExtended private accessControl;
    AccessControlHandler private accessControlHandler;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        accessControl = IAccessControlExtended(
            vyperDeployer.deployContract("src/snekmate/auth/mocks/", "access_control_mock")
        );
        accessControlHandler = new AccessControlHandler(
            accessControl,
            deployer,
            DEFAULT_ADMIN_ROLE,
            MINTER_ROLE,
            PAUSER_ROLE
        );
        targetContract(address(accessControlHandler));
    }

    function statefulFuzzHasRole() public view {
        assertEq(
            accessControl.hasRole(DEFAULT_ADMIN_ROLE, deployer),
            accessControlHandler.hasRole(DEFAULT_ADMIN_ROLE, deployer)
        );
        assertEq(accessControl.hasRole(MINTER_ROLE, deployer), accessControlHandler.hasRole(MINTER_ROLE, deployer));
        assertEq(accessControl.hasRole(PAUSER_ROLE, deployer), accessControlHandler.hasRole(PAUSER_ROLE, deployer));
    }

    function statefulFuzzGetRoleAdmin() public view {
        assertEq(accessControl.getRoleAdmin(DEFAULT_ADMIN_ROLE), accessControlHandler.getRoleAdmin(DEFAULT_ADMIN_ROLE));
        assertEq(accessControl.getRoleAdmin(MINTER_ROLE), accessControlHandler.getRoleAdmin(MINTER_ROLE));
        assertEq(accessControl.getRoleAdmin(PAUSER_ROLE), accessControlHandler.getRoleAdmin(PAUSER_ROLE));
    }
}

contract AccessControlHandler {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable DEFAULT_ADMIN_ROLE;
    bytes32 private immutable MINTER_ROLE;
    bytes32 private immutable PAUSER_ROLE;
    /* solhint-enable var-name-mixedcase */

    mapping(bytes32 => mapping(address => bool)) public hasRole;
    mapping(bytes32 => bytes32) public getRoleAdmin;

    IAccessControlExtended private accessControl;

    constructor(
        IAccessControlExtended accessControl_,
        address defaultAdmin_,
        bytes32 adminRole_,
        bytes32 minterRole_,
        bytes32 pauserRole_
    ) {
        accessControl = accessControl_;
        DEFAULT_ADMIN_ROLE = adminRole_;
        MINTER_ROLE = minterRole_;
        PAUSER_ROLE = pauserRole_;
        hasRole[DEFAULT_ADMIN_ROLE][defaultAdmin_] = true;
        hasRole[MINTER_ROLE][defaultAdmin_] = true;
        hasRole[PAUSER_ROLE][defaultAdmin_] = true;
    }

    function grantRole(bytes32 role, address account) public {
        accessControl.grantRole(role, account);
        hasRole[role][account] = true;
    }

    function revokeRole(bytes32 role, address account) public {
        accessControl.revokeRole(role, account);
        hasRole[role][account] = false;
    }

    function renounceRole(bytes32 role, address account) public {
        accessControl.renounceRole(role, account);
        hasRole[role][account] = false;
    }

    function set_role_admin(bytes32 role, bytes32 adminRole) public {
        accessControl.set_role_admin(role, adminRole);
        getRoleAdmin[role] = adminRole;
    }
}
