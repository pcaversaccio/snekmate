// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";

import {ERC721ReceiverMock} from "../tokens/mocks/ERC721ReceiverMock.sol";
import {ERC1155ReceiverMock} from "../tokens/mocks/ERC1155ReceiverMock.sol";
import {CallReceiverMock} from "./mocks/CallReceiverMock.sol";

import {IERC721Extended} from "../tokens/interfaces/IERC721Extended.sol";
import {IERC1155Extended} from "../tokens/interfaces/IERC1155Extended.sol";
import {ITimelockController} from "./interfaces/ITimelockController.sol";

/**
 * @dev The standard access control functionalities are not tested as they
 * are imported via the `AccessControl` module. See `AccessControl.t.sol`
 * for the corresponding tests. However, please integrate these tests into
 * your own test suite before deploying `TimelockController` into production!
 */
contract TimelockControllerTest is Test {
    bytes32 private constant DEFAULT_ADMIN_ROLE = bytes32(0);
    bytes32 private constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 private constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 private constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");

    bytes4 private constant IERC721_TOKENRECEIVER_SELECTOR =
        ERC721ReceiverMock.onERC721Received.selector;
    bytes4 private constant IERC1155_TOKENRECEIVER_SINGLE_SELECTOR =
        ERC1155ReceiverMock.onERC1155Received.selector;
    bytes4 private constant IERC1155_TOKENRECEIVER_BATCH_SELECTOR =
        ERC1155ReceiverMock.onERC1155BatchReceived.selector;

    uint256 private constant MIN_DELAY = 2 days;
    uint256 private constant DONE_TIMESTAMP = 1;

    address private constant PROPOSER_ONE =
        address(uint160(uint256(keccak256(abi.encodePacked("PROPOSER_ONE")))));
    address private constant PROPOSER_TWO =
        address(uint160(uint256(keccak256(abi.encodePacked("PROPOSER_TWO")))));
    address private constant EXECUTOR_ONE =
        address(uint160(uint256(keccak256(abi.encodePacked("EXECUTOR_ONE")))));
    address private constant EXECUTOR_TWO =
        address(uint160(uint256(keccak256(abi.encodePacked("EXECUTOR_TWO")))));
    address private constant STRANGER =
        address(uint160(uint256(keccak256(abi.encodePacked("STRANGER")))));

    bytes32 private constant NO_PREDECESSOR = bytes32("");
    bytes32 private constant EMPTY_SALT = bytes32("");
    bytes32 private constant SALT = keccak256("WAGMI");

    VyperDeployer private vyperDeployer = new VyperDeployer();
    CallReceiverMock private callReceiverMock = new CallReceiverMock();

    ITimelockController private timelockController;
    ITimelockController private timelockControllerInitialEventEmptyAdmin;
    ITimelockController private timelockControllerInitialEventNonEmptyAdmin;
    IERC721Extended private erc721Mock;
    IERC1155Extended private erc1155Mock;

    address private deployer = address(vyperDeployer);
    address private self = address(this);
    address private zeroAddress = address(0);
    address private target = address(callReceiverMock);
    address private timelockControllerAddr;
    address private timelockControllerInitialEventEmptyAdminAddr;
    address private timelockControllerInitialEventNonEmptyAdminAddr;

    address[2] private proposers = [PROPOSER_ONE, PROPOSER_TWO];
    address[2] private executors = [EXECUTOR_ONE, EXECUTOR_TWO];

    /**
     * @dev An `internal` helper function to check whether a specific role `role`
     * is not assigned to an array of addresses with the length 2.
     * @param accessControl The contract that implements the `IAccessControl` interface.
     * @param role The 32-byte role definition.
     * @param addresses The 20-byte array with the length 2 of accounts to be checked.
     */
    function checkRoleNotSetForAddresses(
        IAccessControl accessControl,
        bytes32 role,
        address[2] storage addresses
    ) internal view {
        assertTrue(
            !accessControl.hasRole(role, addresses[0]) &&
                !accessControl.hasRole(role, addresses[1])
        );
    }

    function setUp() public {
        address[] memory proposers_ = new address[](2);
        proposers_[0] = proposers[0];
        proposers_[1] = proposers[1];
        address[] memory executors_ = new address[](2);
        executors_[0] = executors[0];
        executors_[1] = executors[1];

        bytes memory args = abi.encode(MIN_DELAY, proposers_, executors_, self);
        timelockController = ITimelockController(
            vyperDeployer.deployContract(
                "src/snekmate/governance/mocks/",
                "TimelockControllerMock",
                args
            )
        );
        timelockControllerAddr = address(timelockController);
    }

    function testInitialSetup() public {
        assertEq(timelockController.DEFAULT_ADMIN_ROLE(), DEFAULT_ADMIN_ROLE);
        assertEq(timelockController.PROPOSER_ROLE(), PROPOSER_ROLE);
        assertEq(timelockController.EXECUTOR_ROLE(), EXECUTOR_ROLE);
        assertEq(timelockController.CANCELLER_ROLE(), CANCELLER_ROLE);
        assertEq(
            timelockController.IERC721_TOKENRECEIVER_SELECTOR(),
            IERC721_TOKENRECEIVER_SELECTOR
        );
        assertEq(
            timelockController.IERC1155_TOKENRECEIVER_SINGLE_SELECTOR(),
            IERC1155_TOKENRECEIVER_SINGLE_SELECTOR
        );
        assertEq(
            timelockController.IERC1155_TOKENRECEIVER_BATCH_SELECTOR(),
            IERC1155_TOKENRECEIVER_BATCH_SELECTOR
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.DEFAULT_ADMIN_ROLE(),
                timelockControllerAddr
            )
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.DEFAULT_ADMIN_ROLE(),
                self
            )
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.PROPOSER_ROLE(),
                PROPOSER_ONE
            )
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.PROPOSER_ROLE(),
                PROPOSER_TWO
            )
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.CANCELLER_ROLE(),
                PROPOSER_ONE
            )
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.CANCELLER_ROLE(),
                PROPOSER_TWO
            )
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.EXECUTOR_ROLE(),
                EXECUTOR_ONE
            )
        );
        assertTrue(
            timelockController.hasRole(
                timelockController.EXECUTOR_ROLE(),
                EXECUTOR_TWO
            )
        );
        assertTrue(
            !timelockController.hasRole(
                timelockController.PROPOSER_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockController.hasRole(
                timelockController.CANCELLER_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockController.hasRole(
                timelockController.EXECUTOR_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockController.hasRole(
                timelockController.PROPOSER_ROLE(),
                timelockControllerAddr
            )
        );
        assertTrue(
            !timelockController.hasRole(
                timelockController.CANCELLER_ROLE(),
                timelockControllerAddr
            )
        );
        assertTrue(
            !timelockController.hasRole(
                timelockController.EXECUTOR_ROLE(),
                timelockControllerAddr
            )
        );
        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.DEFAULT_ADMIN_ROLE(),
            proposers
        );
        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.EXECUTOR_ROLE(),
            proposers
        );
        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.DEFAULT_ADMIN_ROLE(),
            executors
        );
        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.PROPOSER_ROLE(),
            executors
        );
        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.CANCELLER_ROLE(),
            executors
        );
        assertEq(timelockController.get_minimum_delay(), MIN_DELAY);

        address[] memory proposers_ = new address[](2);
        proposers_[0] = proposers[0];
        proposers_[1] = proposers[1];
        address[] memory executors_ = new address[](2);
        executors_[0] = executors[0];
        executors_[1] = executors[1];
        bytes memory argsEmptyAdmin = abi.encode(
            MIN_DELAY,
            proposers_,
            executors_,
            zeroAddress
        );
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(
            DEFAULT_ADMIN_ROLE,
            vm.computeCreateAddress(deployer, vm.getNonce(deployer)),
            deployer
        );
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(PROPOSER_ROLE, proposers[0], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(CANCELLER_ROLE, proposers[0], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(PROPOSER_ROLE, proposers[1], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(CANCELLER_ROLE, proposers[1], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(EXECUTOR_ROLE, executors[0], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(EXECUTOR_ROLE, executors[1], deployer);
        vm.expectEmit(true, true, false, false);
        emit ITimelockController.MinimumDelayChange(0, MIN_DELAY);
        timelockControllerInitialEventEmptyAdmin = ITimelockController(
            vyperDeployer.deployContract(
                "src/snekmate/governance/mocks/",
                "TimelockControllerMock",
                argsEmptyAdmin
            )
        );
        timelockControllerInitialEventEmptyAdminAddr = address(
            timelockControllerInitialEventEmptyAdmin
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin.DEFAULT_ADMIN_ROLE(),
            DEFAULT_ADMIN_ROLE
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin.PROPOSER_ROLE(),
            PROPOSER_ROLE
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin.EXECUTOR_ROLE(),
            EXECUTOR_ROLE
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin.CANCELLER_ROLE(),
            CANCELLER_ROLE
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin
                .IERC721_TOKENRECEIVER_SELECTOR(),
            IERC721_TOKENRECEIVER_SELECTOR
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin
                .IERC1155_TOKENRECEIVER_SINGLE_SELECTOR(),
            IERC1155_TOKENRECEIVER_SINGLE_SELECTOR
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin
                .IERC1155_TOKENRECEIVER_BATCH_SELECTOR(),
            IERC1155_TOKENRECEIVER_BATCH_SELECTOR
        );
        assertTrue(
            timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.DEFAULT_ADMIN_ROLE(),
                timelockControllerInitialEventEmptyAdminAddr
            )
        );
        assertTrue(
            !timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.DEFAULT_ADMIN_ROLE(),
                self
            )
        );
        assertTrue(
            timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.PROPOSER_ROLE(),
                PROPOSER_ONE
            )
        );
        assertTrue(
            timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.PROPOSER_ROLE(),
                PROPOSER_TWO
            )
        );
        assertTrue(
            timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.CANCELLER_ROLE(),
                PROPOSER_ONE
            )
        );
        assertTrue(
            timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.CANCELLER_ROLE(),
                PROPOSER_TWO
            )
        );
        assertTrue(
            timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.EXECUTOR_ROLE(),
                EXECUTOR_ONE
            )
        );
        assertTrue(
            timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.EXECUTOR_ROLE(),
                EXECUTOR_TWO
            )
        );
        assertTrue(
            !timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.PROPOSER_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.CANCELLER_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.EXECUTOR_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.PROPOSER_ROLE(),
                timelockControllerInitialEventEmptyAdminAddr
            )
        );
        assertTrue(
            !timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.CANCELLER_ROLE(),
                timelockControllerInitialEventEmptyAdminAddr
            )
        );
        assertTrue(
            !timelockControllerInitialEventEmptyAdmin.hasRole(
                timelockControllerInitialEventEmptyAdmin.EXECUTOR_ROLE(),
                timelockControllerInitialEventEmptyAdminAddr
            )
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventEmptyAdmin,
            timelockControllerInitialEventEmptyAdmin.DEFAULT_ADMIN_ROLE(),
            proposers
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventEmptyAdmin,
            timelockControllerInitialEventEmptyAdmin.EXECUTOR_ROLE(),
            proposers
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventEmptyAdmin,
            timelockControllerInitialEventEmptyAdmin.DEFAULT_ADMIN_ROLE(),
            executors
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventEmptyAdmin,
            timelockControllerInitialEventEmptyAdmin.PROPOSER_ROLE(),
            executors
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventEmptyAdmin,
            timelockControllerInitialEventEmptyAdmin.CANCELLER_ROLE(),
            executors
        );
        assertEq(
            timelockControllerInitialEventEmptyAdmin.get_minimum_delay(),
            MIN_DELAY
        );

        bytes memory argsNonEmptyAdmin = abi.encode(
            MIN_DELAY,
            proposers_,
            executors_,
            self
        );
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(
            DEFAULT_ADMIN_ROLE,
            vm.computeCreateAddress(deployer, vm.getNonce(deployer)),
            deployer
        );
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(DEFAULT_ADMIN_ROLE, self, deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(PROPOSER_ROLE, proposers[0], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(CANCELLER_ROLE, proposers[0], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(PROPOSER_ROLE, proposers[1], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(CANCELLER_ROLE, proposers[1], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(EXECUTOR_ROLE, executors[0], deployer);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleGranted(EXECUTOR_ROLE, executors[1], deployer);
        vm.expectEmit(true, true, false, false);
        emit ITimelockController.MinimumDelayChange(0, MIN_DELAY);
        timelockControllerInitialEventNonEmptyAdmin = ITimelockController(
            vyperDeployer.deployContract(
                "src/snekmate/governance/mocks/",
                "TimelockControllerMock",
                argsNonEmptyAdmin
            )
        );
        timelockControllerInitialEventNonEmptyAdminAddr = address(
            timelockControllerInitialEventNonEmptyAdmin
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin.DEFAULT_ADMIN_ROLE(),
            DEFAULT_ADMIN_ROLE
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin.PROPOSER_ROLE(),
            PROPOSER_ROLE
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin.EXECUTOR_ROLE(),
            EXECUTOR_ROLE
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin.CANCELLER_ROLE(),
            CANCELLER_ROLE
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin
                .IERC721_TOKENRECEIVER_SELECTOR(),
            IERC721_TOKENRECEIVER_SELECTOR
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin
                .IERC1155_TOKENRECEIVER_SINGLE_SELECTOR(),
            IERC1155_TOKENRECEIVER_SINGLE_SELECTOR
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin
                .IERC1155_TOKENRECEIVER_BATCH_SELECTOR(),
            IERC1155_TOKENRECEIVER_BATCH_SELECTOR
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin
                    .DEFAULT_ADMIN_ROLE(),
                timelockControllerInitialEventNonEmptyAdminAddr
            )
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin
                    .DEFAULT_ADMIN_ROLE(),
                self
            )
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.PROPOSER_ROLE(),
                PROPOSER_ONE
            )
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.PROPOSER_ROLE(),
                PROPOSER_TWO
            )
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.CANCELLER_ROLE(),
                PROPOSER_ONE
            )
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.CANCELLER_ROLE(),
                PROPOSER_TWO
            )
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.EXECUTOR_ROLE(),
                EXECUTOR_ONE
            )
        );
        assertTrue(
            timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.EXECUTOR_ROLE(),
                EXECUTOR_TWO
            )
        );
        assertTrue(
            !timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.PROPOSER_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.CANCELLER_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.EXECUTOR_ROLE(),
                self
            )
        );
        assertTrue(
            !timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.PROPOSER_ROLE(),
                timelockControllerInitialEventNonEmptyAdminAddr
            )
        );
        assertTrue(
            !timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.CANCELLER_ROLE(),
                timelockControllerInitialEventNonEmptyAdminAddr
            )
        );
        assertTrue(
            !timelockControllerInitialEventNonEmptyAdmin.hasRole(
                timelockControllerInitialEventNonEmptyAdmin.EXECUTOR_ROLE(),
                timelockControllerInitialEventNonEmptyAdminAddr
            )
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventNonEmptyAdmin,
            timelockControllerInitialEventNonEmptyAdmin.DEFAULT_ADMIN_ROLE(),
            proposers
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventNonEmptyAdmin,
            timelockControllerInitialEventNonEmptyAdmin.EXECUTOR_ROLE(),
            proposers
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventNonEmptyAdmin,
            timelockControllerInitialEventNonEmptyAdmin.DEFAULT_ADMIN_ROLE(),
            executors
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventNonEmptyAdmin,
            timelockControllerInitialEventNonEmptyAdmin.PROPOSER_ROLE(),
            executors
        );
        checkRoleNotSetForAddresses(
            timelockControllerInitialEventNonEmptyAdmin,
            timelockControllerInitialEventNonEmptyAdmin.CANCELLER_ROLE(),
            executors
        );
        assertEq(
            timelockControllerInitialEventNonEmptyAdmin.get_minimum_delay(),
            MIN_DELAY
        );
    }

    function testCanReceiveEther() public {
        payable(timelockControllerAddr).transfer(0.5 ether);
        assertEq(timelockControllerAddr.balance, 0.5 ether);
    }

    function testSupportsInterfaceSuccess() public view {
        assertTrue(
            timelockController.supportsInterface(type(IERC165).interfaceId)
        );
        assertTrue(
            timelockController.supportsInterface(
                type(IAccessControl).interfaceId
            )
        );
        assertTrue(
            timelockController.supportsInterface(
                type(IERC1155Receiver).interfaceId
            )
        );
    }

    function testSupportsInterfaceSuccessGasCost() public view {
        uint256 startGas = gasleft();
        timelockController.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(
            gasUsed <= 30_000 &&
                timelockController.supportsInterface(type(IERC165).interfaceId)
        );
    }

    function testSupportsInterfaceInvalidInterfaceId() public view {
        assertTrue(!timelockController.supportsInterface(0x0011bbff));
    }

    function testSupportsInterfaceInvalidInterfaceIdGasCost() public view {
        uint256 startGas = gasleft();
        timelockController.supportsInterface(0x0011bbff);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(
            gasUsed <= 30_000 &&
                !timelockController.supportsInterface(0x0011bbff)
        );
    }

    function testHashOperation() public view {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(
            operationId,
            keccak256(
                abi.encode(target, amount, payload, NO_PREDECESSOR, EMPTY_SALT)
            )
        );
    }

    function testScheduleAndExecuteWithEmptySalt() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(vm.load(target, slot), bytes32(uint256(0)));
        assertTrue(!timelockController.is_operation(operationId));
        assertEq(timelockController.get_operation_state(operationId), 1);
        assertEq(timelockController.get_timestamp(operationId), 0);

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation(operationId));
        assertEq(
            timelockController.get_timestamp(operationId),
            block.timestamp + MIN_DELAY
        );
        vm.stopPrank();

        assertEq(timelockController.get_operation_state(operationId), 2);
        vm.warp(block.timestamp + MIN_DELAY);
        assertEq(timelockController.get_operation_state(operationId), 4);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            target,
            amount,
            payload
        );
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(vm.load(target, slot), value);
        assertTrue(timelockController.is_operation(operationId));
        assertEq(timelockController.get_timestamp(operationId), DONE_TIMESTAMP);
        assertEq(timelockController.get_operation_state(operationId), 8);
        vm.stopPrank();
    }

    function testScheduleAndExecuteWithNonEmptySalt() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            SALT
        );
        assertEq(vm.load(target, slot), bytes32(uint256(0)));
        assertTrue(!timelockController.is_operation(operationId));
        assertEq(timelockController.get_operation_state(operationId), 1);
        assertEq(timelockController.get_timestamp(operationId), 0);

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        vm.expectEmit(true, false, false, true);
        emit ITimelockController.CallSalt(operationId, SALT);
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation(operationId));
        assertEq(
            timelockController.get_timestamp(operationId),
            block.timestamp + MIN_DELAY
        );
        vm.stopPrank();

        assertEq(timelockController.get_operation_state(operationId), 2);
        vm.warp(block.timestamp + MIN_DELAY);
        assertEq(timelockController.get_operation_state(operationId), 4);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            target,
            amount,
            payload
        );
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            SALT
        );
        assertEq(vm.load(target, slot), value);
        assertTrue(timelockController.is_operation(operationId));
        assertEq(timelockController.get_timestamp(operationId), DONE_TIMESTAMP);
        assertEq(timelockController.get_operation_state(operationId), 8);
        vm.stopPrank();
    }

    function testOperationAlreadyScheduled() public {
        uint256 amount = 0;
        bytes memory payload = new bytes(0);
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.expectRevert("TimelockController: operation already scheduled");
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();
    }

    function testOperationInsufficientDelay() public {
        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.schedule(
            target,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY - 1
        );
    }

    function testOperationEqualAndGreaterMinimumDelay() public {
        uint256 amount = 0;
        bytes memory payload = new bytes(0);
        bytes32 operationId = timelockController.hash_operation(
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation(operationId));
        vm.stopPrank();

        operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            SALT
        );
        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY + 1
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY + 1
        );
        assertTrue(timelockController.is_operation(operationId));
        vm.stopPrank();
    }

    function testOperationMinimumDelayUpdate() public {
        uint256 amount = 0;
        bytes memory payload = new bytes(0);
        bytes32 operationId = timelockController.hash_operation(
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        uint256 operationTimestampBefore = timelockController.get_timestamp(
            operationId
        );
        vm.stopPrank();

        vm.startPrank(timelockControllerAddr);
        vm.expectEmit(true, true, false, false);
        emit ITimelockController.MinimumDelayChange(
            MIN_DELAY,
            MIN_DELAY + 31 days
        );
        timelockController.update_delay(MIN_DELAY + 31 days);
        uint256 operationTimestampAfter = timelockController.get_timestamp(
            operationId
        );
        assertEq(timelockController.get_minimum_delay(), MIN_DELAY + 31 days);
        assertEq(operationTimestampAfter, operationTimestampBefore);
        vm.stopPrank();
    }

    function testCompletePipelineOperationMinimumDelayUpdate() public {
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            timelockController.update_delay.selector,
            MIN_DELAY + 31 days
        );
        bytes32 operationId = timelockController.hash_operation(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            timelockControllerAddr,
            amount,
            payload
        );
        timelockController.execute(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(timelockController.get_minimum_delay(), MIN_DELAY + 31 days);
        vm.stopPrank();
    }

    function testOperationOperationIsNotReady() public {
        uint256 amount = 0;
        bytes memory payload = new bytes(0);
        bytes32 operationId = timelockController.hash_operation(
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY - 2 days);
        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            zeroAddress,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testOperationPredecessorNotExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId1 = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 operationId2 = timelockController.hash_operation(
            target,
            amount,
            payload,
            operationId1,
            SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId1,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId2,
            0,
            target,
            amount,
            payload,
            operationId1,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            operationId1,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(target, amount, payload, operationId1, SALT);
    }

    function testOperationPredecessorNotScheduled() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId1 = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 operationId2 = timelockController.hash_operation(
            target,
            amount,
            payload,
            operationId1,
            SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId2,
            0,
            target,
            amount,
            payload,
            operationId1,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            operationId1,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(target, amount, payload, operationId1, SALT);
    }

    function testOperationPredecessorInvalid() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 invalidPredecessor = keccak256("Invalid Predecessor");
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            invalidPredecessor,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            invalidPredecessor,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            invalidPredecessor,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload,
            invalidPredecessor,
            EMPTY_SALT
        );
    }

    function testOperationTargetRevert() public {
        uint256 amount = 0;
        bytes memory payload1 = abi.encodeWithSelector(
            callReceiverMock.mockFunctionRevertsWithReason.selector
        );
        bytes memory payload2 = abi.encodeWithSelector(
            callReceiverMock.mockFunctionRevertsWithEmptyReason.selector
        );
        bytes32 operationId1 = timelockController.hash_operation(
            target,
            amount,
            payload1,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 operationId2 = timelockController.hash_operation(
            target,
            amount,
            payload2,
            NO_PREDECESSOR,
            SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId1,
            0,
            target,
            amount,
            payload1,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload1,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId2,
            0,
            target,
            amount,
            payload2,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload2,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("CallReceiverMock: reverting");
        vm.startPrank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload1,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        vm.expectRevert("TimelockController: underlying transaction reverted");
        timelockController.execute(
            target,
            amount,
            payload2,
            NO_PREDECESSOR,
            SALT
        );
        vm.stopPrank();
    }

    function testOperationPredecessorMultipleNotExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        payload = abi.encodeWithSelector(
            callReceiverMock.mockFunction.selector
        );
        vm.startPrank(PROPOSER_TWO);
        timelockController.schedule(
            target,
            amount,
            payload,
            operationId,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload,
            operationId,
            EMPTY_SALT
        );
    }

    function testOperationCancelFinished() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            target,
            amount,
            payload
        );
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        vm.stopPrank();

        vm.prank(PROPOSER_ONE);
        vm.expectRevert("TimelockController: operation cannot be cancelled");
        timelockController.cancel(operationId);
    }

    function testOperationPendingIfNotYetExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation_pending(operationId));
        vm.stopPrank();
    }

    function testOperationPendingIfExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            target,
            amount,
            payload
        );
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertTrue(!timelockController.is_operation_pending(operationId));
        vm.stopPrank();
    }

    function testOperationReadyOnTheExecutionTime() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY);
        assertTrue(timelockController.is_operation_ready(operationId));
        vm.stopPrank();
    }

    function testOperationReadyAfterTheExecutionTime() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY + 1 days);
        assertTrue(timelockController.is_operation_ready(operationId));
        vm.stopPrank();
    }

    function testOperationReadyBeforeTheExecutionTime() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY - 1 days);
        assertTrue(!timelockController.is_operation_ready(operationId));
        vm.stopPrank();
    }

    function testOperationHasBeenExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            target,
            amount,
            payload
        );
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertTrue(!timelockController.is_operation_ready(operationId));
        assertTrue(timelockController.is_operation_done(operationId));
        vm.stopPrank();
    }

    function testOperationHasNotBeenExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(!timelockController.is_operation_done(operationId));
        vm.stopPrank();
    }

    function testOperationTimestampHasNotBeenExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertEq(
            timelockController.get_timestamp(operationId),
            block.timestamp + MIN_DELAY
        );
        vm.stopPrank();
    }

    function testOperationTimestampHasBeenExecuted() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            target,
            amount,
            payload
        );
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(timelockController.get_timestamp(operationId), DONE_TIMESTAMP);
        vm.stopPrank();
    }

    function testHashOperationBatch() public view {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(
            batchedOperationId,
            keccak256(
                abi.encode(
                    targets,
                    amounts,
                    payloads,
                    NO_PREDECESSOR,
                    EMPTY_SALT
                )
            )
        );
    }

    function testBatchScheduleAndExecuteWithEmptySalt() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(vm.load(target, slot), bytes32(uint256(0)));
        assertTrue(!timelockController.is_operation(batchedOperationId));
        assertEq(timelockController.get_operation_state(batchedOperationId), 1);
        assertEq(timelockController.get_timestamp(batchedOperationId), 0);

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation(batchedOperationId));
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            block.timestamp + MIN_DELAY
        );
        vm.stopPrank();

        assertEq(timelockController.get_operation_state(batchedOperationId), 2);
        vm.warp(block.timestamp + MIN_DELAY);
        assertEq(timelockController.get_operation_state(batchedOperationId), 4);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(vm.load(target, slot), value);
        assertTrue(timelockController.is_operation(batchedOperationId));
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            DONE_TIMESTAMP
        );
        assertEq(timelockController.get_operation_state(batchedOperationId), 8);
        vm.stopPrank();
    }

    function testBatchScheduleAndExecuteWithNonEmptySalt() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT
        );
        assertEq(vm.load(target, slot), bytes32(uint256(0)));
        assertTrue(!timelockController.is_operation(batchedOperationId));
        assertEq(timelockController.get_operation_state(batchedOperationId), 1);
        assertEq(timelockController.get_timestamp(batchedOperationId), 0);

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
            vm.expectEmit(true, false, false, true);
            emit ITimelockController.CallSalt(batchedOperationId, SALT);
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation(batchedOperationId));
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            block.timestamp + MIN_DELAY
        );
        vm.stopPrank();

        assertEq(timelockController.get_operation_state(batchedOperationId), 2);
        vm.warp(block.timestamp + MIN_DELAY);
        assertEq(timelockController.get_operation_state(batchedOperationId), 4);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT
        );
        assertEq(vm.load(target, slot), value);
        assertTrue(timelockController.is_operation(batchedOperationId));
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            DONE_TIMESTAMP
        );
        assertEq(timelockController.get_operation_state(batchedOperationId), 8);
        vm.stopPrank();
    }

    function testBatchOperationAlreadyScheduled() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.expectRevert("TimelockController: operation already scheduled");
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();
    }

    function testBatchInsufficientDelay() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY - 1
        );
    }

    function testBatchEqualAndGreaterMinimumDelay() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation(batchedOperationId));
        vm.stopPrank();

        batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT
        );
        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY + 1
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY + 1
        );
        assertTrue(timelockController.is_operation(batchedOperationId));
        vm.stopPrank();
    }

    function testBatchMinimumDelayUpdate() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        uint256 operationTimestampBefore = timelockController.get_timestamp(
            batchedOperationId
        );
        vm.stopPrank();

        vm.startPrank(address(timelockController));
        timelockController.update_delay(MIN_DELAY + 31 days);
        uint256 operationTimestampAfter = timelockController.get_timestamp(
            batchedOperationId
        );
        assertEq(timelockController.get_minimum_delay(), MIN_DELAY + 31 days);
        assertEq(operationTimestampAfter, operationTimestampBefore);
        vm.stopPrank();
    }

    function testBatchOperationIsNotReady() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY - 2 days);
        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testBatchPredecessorNotExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId1 = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 batchedOperationId2 = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId1,
            SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId1,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId2,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                batchedOperationId1,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId1,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId1,
            SALT
        );
    }

    function testBatchPredecessorNotScheduled() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId1 = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 batchedOperationId2 = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId1,
            SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId2,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                batchedOperationId1,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId1,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId1,
            SALT
        );
    }

    function testBatchPredecessorInvalid() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 invalidPredecessor = keccak256("Invalid Predecessor");
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            invalidPredecessor,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                invalidPredecessor,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            invalidPredecessor,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            invalidPredecessor,
            EMPTY_SALT
        );
    }

    function testBatchTargetRevert() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes[] memory payloads1 = new bytes[](1);
        payloads1[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionRevertsWithReason.selector
        );
        bytes[] memory payloads2 = new bytes[](1);
        payloads2[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionRevertsWithEmptyReason.selector
        );
        bytes32 batchedOperationId1 = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads1,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 batchedOperationId2 = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads2,
            NO_PREDECESSOR,
            SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId1,
                i,
                targets[i],
                amounts[i],
                payloads1[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads1,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId2,
                i,
                targets[i],
                amounts[i],
                payloads2[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads2,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("CallReceiverMock: reverting");
        vm.startPrank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads1,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        vm.expectRevert("TimelockController: underlying transaction reverted");
        timelockController.execute_batch(
            targets,
            amounts,
            payloads2,
            NO_PREDECESSOR,
            SALT
        );
        vm.stopPrank();
    }

    function testBatchPredecessorMultipleNotExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunction.selector
        );
        vm.startPrank(PROPOSER_ONE);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            batchedOperationId,
            EMPTY_SALT
        );
    }

    function testBatchCancelFinished() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        vm.stopPrank();

        vm.prank(PROPOSER_ONE);
        vm.expectRevert("TimelockController: operation cannot be cancelled");
        timelockController.cancel(batchedOperationId);
    }

    function testBatchPendingIfNotYetExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(timelockController.is_operation_pending(batchedOperationId));
        vm.stopPrank();
    }

    function testBatchPendingIfExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertTrue(
            !timelockController.is_operation_pending(batchedOperationId)
        );
        vm.stopPrank();
    }

    function testBatchReadyOnTheExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY);
        assertTrue(timelockController.is_operation_ready(batchedOperationId));
        vm.stopPrank();
    }

    function testBatchReadyAfterTheExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY + 1 days);
        assertTrue(timelockController.is_operation_ready(batchedOperationId));
        vm.stopPrank();
    }

    function testBatchReadyBeforeTheExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY - 1 days);
        assertTrue(!timelockController.is_operation_ready(batchedOperationId));
        vm.stopPrank();
    }

    function testBatchHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertTrue(!timelockController.is_operation_ready(batchedOperationId));
        assertTrue(timelockController.is_operation_done(batchedOperationId));
        vm.stopPrank();
    }

    function testBatchHasNotBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        assertTrue(!timelockController.is_operation_done(batchedOperationId));
        vm.stopPrank();
    }

    function testBatchTimestampHasNotBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationId
        );
        assertEq(operationTimestamp, block.timestamp + MIN_DELAY);
        vm.stopPrank();
    }

    function testBatchTimestampHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            DONE_TIMESTAMP
        );
        vm.stopPrank();
    }

    function testReturnsLaterMinimumDelayForCalls() public {
        uint256 newMinDelay = 31 days;
        vm.startPrank(timelockControllerAddr);
        vm.expectEmit(true, true, false, false);
        emit ITimelockController.MinimumDelayChange(
            timelockController.get_minimum_delay(),
            newMinDelay
        );
        timelockController.update_delay(newMinDelay);
        vm.stopPrank();
        assertEq(timelockController.get_minimum_delay(), newMinDelay);
    }

    function testInvalidOperation() public view {
        assertTrue(!timelockController.is_operation(keccak256("Invalid")));
    }

    function testRevertWhenNotTimelock() public {
        vm.expectRevert("TimelockController: caller must be timelock");
        vm.prank(STRANGER);
        timelockController.update_delay(3 days);
    }

    function testAdminCannotBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(self);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testAdminCannotSchedule() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(self);
        timelockController.schedule(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testAdminCannotBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(self);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testAdminCannotExecute() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(self);
        timelockController.execute(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testAdminCannotCancel() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(self);
        timelockController.cancel(EMPTY_SALT);
    }

    function testProposerCanBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);
        vm.startPrank(PROPOSER_ONE);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.prank(PROPOSER_TWO);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();
    }

    function testProposerCanSchedule() public {
        vm.startPrank(PROPOSER_ONE);
        timelockController.schedule(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.startPrank(PROPOSER_TWO);
        timelockController.schedule(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
        vm.stopPrank();
    }

    function testProposerCannotBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_TWO);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT
        );
    }

    function testProposerCannotExecute() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_ONE);
        timelockController.execute(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_TWO);
        timelockController.execute(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            SALT
        );
    }

    function testProposerCanCancel() public {
        vm.expectRevert("TimelockController: operation cannot be cancelled");
        vm.prank(PROPOSER_ONE);
        timelockController.cancel(EMPTY_SALT);

        vm.expectRevert("TimelockController: operation cannot be cancelled");
        vm.prank(PROPOSER_TWO);
        timelockController.cancel(EMPTY_SALT);
    }

    function testExecutorCannotBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_ONE);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_TWO);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
    }

    function testExecutorCannotSchedule() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_ONE);
        timelockController.schedule(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_TWO);
        timelockController.schedule(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            SALT,
            MIN_DELAY
        );
    }

    function testExecutorCanBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_TWO);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            SALT
        );
    }

    function testExecutorCanExecute() public {
        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_TWO);
        timelockController.execute(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            SALT
        );
    }

    function testExecutorCannotCancel() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_ONE);
        timelockController.cancel(EMPTY_SALT);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_TWO);
        timelockController.cancel(EMPTY_SALT);
    }

    function testStrangerCannotBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testStrangerCannotSchedule() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.schedule(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testStrangerCannotBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testStrangerCannotExecute() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.execute(
            zeroAddress,
            0,
            new bytes(0),
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testStrangerCannotCancel() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.cancel(EMPTY_SALT);
    }

    function testCancellerCanCancelOperation() public {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.expectEmit(true, false, false, false);
        emit ITimelockController.Cancelled(batchedOperationId);
        timelockController.cancel(batchedOperationId);
        assertTrue(!timelockController.is_operation(batchedOperationId));
        vm.stopPrank();
    }

    function testCompletePipelineOperationSetRoleAdmin() public {
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            timelockController.set_role_admin.selector,
            EXECUTOR_ROLE,
            PROPOSER_ROLE
        );
        bytes32 operationId = timelockController.hash_operation(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(
            EXECUTOR_ROLE,
            DEFAULT_ADMIN_ROLE,
            PROPOSER_ROLE
        );
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            timelockControllerAddr,
            amount,
            payload
        );
        timelockController.execute(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(timelockController.getRoleAdmin(EXECUTOR_ROLE), PROPOSER_ROLE);
        assertTrue(
            timelockController.getRoleAdmin(EXECUTOR_ROLE) != DEFAULT_ADMIN_ROLE
        );
        vm.stopPrank();
    }

    function testCompleteOperationWithAssignExecutorRoleToZeroAddress() public {
        vm.startPrank(timelockControllerAddr);
        timelockController.grantRole(EXECUTOR_ROLE, zeroAddress);
        vm.stopPrank();

        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            timelockController.set_role_admin.selector,
            EXECUTOR_ROLE,
            PROPOSER_ROLE
        );
        bytes32 operationId = timelockController.hash_operation(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(STRANGER);
        vm.expectEmit(true, true, true, false);
        emit IAccessControl.RoleAdminChanged(
            EXECUTOR_ROLE,
            DEFAULT_ADMIN_ROLE,
            PROPOSER_ROLE
        );
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            timelockControllerAddr,
            amount,
            payload
        );
        timelockController.execute(
            timelockControllerAddr,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(timelockController.getRoleAdmin(EXECUTOR_ROLE), PROPOSER_ROLE);
        assertTrue(
            timelockController.getRoleAdmin(EXECUTOR_ROLE) != DEFAULT_ADMIN_ROLE
        );
        vm.stopPrank();
    }

    function testHandleERC721() public {
        bytes memory args = abi.encode(
            "MyNFT",
            "WAGMI",
            "https://www.wagmi.xyz/",
            "MyNFT",
            "1"
        );
        erc721Mock = IERC721Extended(
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "ERC721Mock",
                args
            )
        );
        vm.startPrank(deployer);
        erc721Mock.safe_mint(timelockControllerAddr, "my_awesome_nft_uri_1");
        assertEq(erc721Mock.balanceOf(timelockControllerAddr), 1);
        vm.stopPrank();

        address[] memory targets = new address[](1);
        targets[0] = address(erc721Mock);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(erc721Mock.burn.selector, 0);
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            DONE_TIMESTAMP
        );
        assertEq(erc721Mock.balanceOf(timelockControllerAddr), 0);
        vm.stopPrank();
    }

    function testHandleERC1155() public {
        bytes memory args = abi.encode("https://www.wagmi.xyz/");
        erc1155Mock = IERC1155Extended(
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "ERC1155Mock",
                args
            )
        );
        uint256[] memory ids = new uint256[](2);
        uint256[] memory tokenAmounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        tokenAmounts[0] = 1;
        tokenAmounts[1] = 2;

        vm.startPrank(deployer);
        erc1155Mock.safe_mint(timelockControllerAddr, 0, 1, new bytes(0));
        erc1155Mock.safe_mint_batch(
            timelockControllerAddr,
            ids,
            tokenAmounts,
            new bytes(0)
        );
        assertEq(erc1155Mock.balanceOf(timelockControllerAddr, 0), 1);
        assertEq(erc1155Mock.balanceOf(timelockControllerAddr, 1), 1);
        assertEq(erc1155Mock.balanceOf(timelockControllerAddr, 2), 2);
        vm.stopPrank();

        address[] memory targets = new address[](1);
        targets[0] = address(erc1155Mock);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            erc1155Mock.burn.selector,
            timelockControllerAddr,
            0,
            1
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            DONE_TIMESTAMP
        );
        assertEq(erc1155Mock.balanceOf(timelockControllerAddr, 0), 0);
        vm.stopPrank();
    }

    function testFuzzHashOperation(
        address target_,
        uint256 amount,
        bytes memory payload,
        bytes32 predecessor,
        bytes32 salt
    ) public view {
        bytes32 operationId = timelockController.hash_operation(
            target_,
            amount,
            payload,
            predecessor,
            salt
        );
        assertEq(
            operationId,
            keccak256(abi.encode(target_, amount, payload, predecessor, salt))
        );
    }

    function testFuzzOperationValue(uint256 amount) public {
        amount = bound(amount, 0, type(uint64).max);
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes memory payload = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 operationId = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        deal(timelockControllerAddr, amount);

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallScheduled(
            operationId,
            0,
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        vm.expectEmit(true, true, false, true);
        emit ITimelockController.CallExecuted(
            operationId,
            0,
            target,
            amount,
            payload
        );
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(timelockController.get_timestamp(operationId), DONE_TIMESTAMP);
        assertEq(address(callReceiverMock).balance, amount);
        vm.stopPrank();
    }

    function testFuzzHashOperationBatch(
        address[] memory targets_,
        uint256[] memory amounts,
        bytes[] memory payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public view {
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets_,
            amounts,
            payloads,
            predecessor,
            salt
        );
        assertEq(
            batchedOperationId,
            keccak256(
                abi.encode(targets_, amounts, payloads, predecessor, salt)
            )
        );
    }

    function testFuzzBatchValue(uint256 amount) public {
        amount = bound(amount, 0, type(uint64).max);
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        bytes32 slot = bytes32(uint256(1_337));
        bytes32 value = bytes32(uint256(6_699));
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            callReceiverMock.mockFunctionWritesStorage.selector,
            slot,
            value
        );
        bytes32 batchedOperationId = timelockController.hash_operation_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        deal(timelockControllerAddr, amount);

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallScheduled(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_DELAY);
        vm.startPrank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit ITimelockController.CallExecuted(
                batchedOperationId,
                i,
                targets[i],
                amounts[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            amounts,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        assertEq(
            timelockController.get_timestamp(batchedOperationId),
            DONE_TIMESTAMP
        );
        assertEq(address(callReceiverMock).balance, amounts[0]);
        vm.stopPrank();
    }
}

contract TimelockControllerInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ITimelockController private timelockController;
    TimelockControllerHandler private timelockControllerHandler;

    address private self = address(this);
    address private timelockControllerHandlerAddr;
    uint256 private initialTimestamp;

    function setUp() public {
        initialTimestamp = block.timestamp;

        address[] memory proposers = new address[](1);
        proposers[0] = self;
        address[] memory executors = new address[](1);
        executors[0] = self;
        uint256 minDelay = 2 days;
        bytes memory args = abi.encode(minDelay, proposers, executors, self);
        timelockController = ITimelockController(
            vyperDeployer.deployContract(
                "src/snekmate/governance/mocks/",
                "TimelockControllerMock",
                args
            )
        );
        timelockControllerHandler = new TimelockControllerHandler(
            timelockController,
            minDelay,
            proposers,
            executors,
            self
        );
        timelockControllerHandlerAddr = address(timelockControllerHandler);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = TimelockControllerHandler.schedule.selector;
        selectors[1] = TimelockControllerHandler.execute.selector;
        selectors[2] = TimelockControllerHandler.cancel.selector;
        targetSelector(
            FuzzSelector({
                addr: timelockControllerHandlerAddr,
                selectors: selectors
            })
        );
        targetContract(timelockControllerHandlerAddr);
    }

    /**
     * @dev The number of scheduled transactions cannot exceed the number of
     * executed transactions.
     */
    function statefulFuzzExecutedLessThanOrEqualToScheduled() public view {
        assertTrue(
            timelockControllerHandler.executeCount() <=
                timelockControllerHandler.scheduleCount()
        );
    }

    /**
     * @dev The number of proposals executed must match the count number.
     */
    function statefulFuzzProposalsExecutedMatchCount() public view {
        assertEq(
            timelockControllerHandler.executeCount(),
            timelockControllerHandler.counter()
        );
    }

    /**
     * @dev Proposals can only be scheduled and executed once.
     */
    function statefulFuzzOnceProposalExecution() public {
        uint256[] memory executed = timelockControllerHandler.getExecuted();
        for (uint256 i = 0; i < executed.length; ++i) {
            /**
             * @dev Ensure that the executed proposal cannot be executed again.
             */
            vm.expectRevert("TimelockController: operation is not ready");
            timelockController.execute(
                timelockControllerHandlerAddr,
                0,
                abi.encodeWithSelector(
                    TimelockControllerHandler.increment.selector
                ),
                bytes32(""),
                bytes32(executed[i])
            );
        }
    }

    /**
     * @dev The sum of the executed proposals and the cancelled proposals must
     * be less than or equal to the number of scheduled proposals.
     */
    function statefulFuzzSumOfProposals() public view {
        assertTrue(
            (timelockControllerHandler.cancelCount() +
                timelockControllerHandler.executeCount()) <=
                timelockControllerHandler.scheduleCount()
        );
    }

    /**
     * @dev The executed proposals cannot be cancelled.
     */
    function statefulFuzzExecutedProposalCancellation() public {
        bytes32 operationId;
        uint256[] memory executed = timelockControllerHandler.getExecuted();
        for (uint256 i = 0; i < executed.length; ++i) {
            operationId = timelockController.hash_operation(
                timelockControllerHandlerAddr,
                0,
                abi.encodeWithSelector(
                    TimelockControllerHandler.increment.selector
                ),
                bytes32(""),
                bytes32(executed[i])
            );
            /**
             * @dev Ensure that the executed proposal cannot be cancelled.
             */
            vm.expectRevert(
                "TimelockController: operation cannot be cancelled"
            );
            timelockController.cancel(operationId);
        }
    }

    /**
     * @dev The execution of a proposal that has been cancelled is not possible.
     */
    function statefulFuzzExecutingCancelledProposal() public {
        bool isPending;
        uint256[] memory cancelled = timelockControllerHandler.getCancelled();
        uint256[] memory pending = timelockControllerHandler.getPending();
        for (uint256 i = 0; i < cancelled.length; ++i) {
            for (uint256 j = 0; i < pending.length; ++i) {
                /**
                 * @dev Check if a `cancelled` element is also part of the `pending` array.
                 */
                isPending = (cancelled[i] == pending[j]) ? true : false;
                if (isPending) {
                    break;
                }
            }
            if (!isPending) {
                /**
                 * @dev Ensure that the cancelled proposal cannot be executed.
                 */
                vm.expectRevert("TimelockController: operation is not ready");
                timelockController.execute(
                    timelockControllerHandlerAddr,
                    0,
                    abi.encodeWithSelector(
                        TimelockControllerHandler.increment.selector
                    ),
                    bytes32(""),
                    bytes32(cancelled[i])
                );
            }
            isPending = false;
        }
    }

    /**
     * @dev The execution of a proposal that is not ready is not possible.
     */
    function statefulFuzzExecutingNotReadyProposal() public {
        vm.warp(initialTimestamp);
        uint256[] memory pending = timelockControllerHandler.getPending();
        for (uint256 i = 0; i < pending.length; ++i) {
            /**
             * @dev Ensure that the pending proposal cannot be executed.
             */
            vm.expectRevert("TimelockController: operation is not ready");
            timelockController.execute(
                timelockControllerHandlerAddr,
                0,
                abi.encodeWithSelector(
                    TimelockControllerHandler.increment.selector
                ),
                bytes32(""),
                bytes32(pending[i])
            );
        }
    }
}

contract TimelockControllerHandler is Test {
    uint256 public counter;
    uint256 public scheduleCount;
    uint256 public executeCount;
    uint256 public cancelCount;

    ITimelockController private timelockController;

    address private self = address(this);
    uint256 private minDelay;
    address private admin;
    address private proposer;
    address private executor;
    uint256[] private pending;
    uint256[] private executed;
    uint256[] private cancelled;

    constructor(
        ITimelockController timelockController_,
        uint256 minDelay_,
        address[] memory proposer_,
        address[] memory executor_,
        address admin_
    ) {
        timelockController = timelockController_;
        minDelay = minDelay_;
        proposer = proposer_[0];
        executor = executor_[0];
        admin = admin_;
    }

    function schedule(uint256 random) external {
        vm.startPrank(proposer);
        timelockController.schedule(
            self,
            0,
            abi.encodeWithSelector(this.increment.selector),
            bytes32(""),
            bytes32(random),
            minDelay
        );
        pending.push(random);
        scheduleCount++;
        vm.stopPrank();
    }

    function execute(uint256 random) external {
        if (pending.length == 0 || scheduleCount == 0) {
            return;
        }

        uint256 identifier = random % pending.length;
        uint256 operation = pending[identifier];

        /**
         * @dev Advance the time to make the proposal ready.
         */
        vm.warp(block.timestamp + minDelay);
        vm.startPrank(executor);
        timelockController.execute(
            self,
            0,
            abi.encodeWithSelector(this.increment.selector),
            bytes32(""),
            bytes32(operation)
        );
        delete pending[identifier];
        executed.push(operation);
        executeCount++;
        vm.stopPrank();
    }

    function cancel(uint256 random) external {
        if (pending.length == 0 || scheduleCount == 0) {
            return;
        }

        uint256 identifier = random % pending.length;
        uint256 operation = pending[identifier];

        vm.startPrank(proposer);
        timelockController.cancel(
            timelockController.hash_operation(
                self,
                0,
                abi.encodeWithSelector(this.increment.selector),
                bytes32(""),
                bytes32(operation)
            )
        );
        delete pending[identifier];
        cancelled.push(operation);
        cancelCount++;
        vm.stopPrank();
    }

    function getExecuted() external view returns (uint256[] memory) {
        return executed;
    }

    function getCancelled() external view returns (uint256[] memory) {
        return cancelled;
    }

    function getPending() external view returns (uint256[] memory) {
        return pending;
    }

    function increment() external {
        counter++;
    }
}
