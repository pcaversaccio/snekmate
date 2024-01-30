// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";

import {ERC721ReceiverMock} from "../tokens/mocks/ERC721ReceiverMock.sol";
import {ERC1155ReceiverMock} from "../tokens/mocks/ERC1155ReceiverMock.sol";
import {CallReceiverMock} from "./mocks/CallReceiverMock.sol";

import {ITimelockController} from "./interfaces/ITimelockController.sol";

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
    ) internal {
        for (uint256 i = 0; i < addresses.length; ++i) {
            assertTrue(!accessControl.hasRole(role, addresses[i]));
        }
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
                "src/governance/",
                "TimelockController",
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
            address(0)
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
                "src/governance/",
                "TimelockController",
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
                "src/governance/",
                "TimelockController",
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

    function testSupportsInterfaceSuccess() public {
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

    function testSupportsInterfaceSuccessGasCost() public {
        uint256 startGas = gasleft();
        timelockController.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(
            gasUsed <= 30_000 &&
                timelockController.supportsInterface(type(IERC165).interfaceId)
        );
    }

    function testSupportsInterfaceInvalidInterfaceId() public {
        assertTrue(!timelockController.supportsInterface(0x0011bbff));
    }

    function testSupportsInterfaceInvalidInterfaceIdGasCost() public {
        uint256 startGas = gasleft();
        timelockController.supportsInterface(0x0011bbff);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(
            gasUsed <= 30_000 &&
                !timelockController.supportsInterface(0x0011bbff)
        );
    }

    function testHashOperation() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        assertEq(timelockController.is_operation(operationId), false);
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
        assertEq(timelockController.is_operation(operationId), true);
        assertEq(
            timelockController.get_timestamp(operationId),
            block.timestamp + MIN_DELAY
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
        assertEq(vm.load(target, slot), value);
        assertEq(timelockController.is_operation(operationId), true);
        assertEq(timelockController.get_timestamp(operationId), DONE_TIMESTAMP);
        vm.stopPrank();
    }

    function testScheduleAndExecuteWithNonEmptySalt() public {
        uint256 amount = 0;
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        assertEq(timelockController.is_operation(operationId), false);
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
        assertEq(timelockController.is_operation(operationId), true);
        assertEq(
            timelockController.get_timestamp(operationId),
            block.timestamp + MIN_DELAY
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
            SALT
        );
        assertEq(vm.load(target, slot), value);
        assertEq(timelockController.is_operation(operationId), true);
        assertEq(timelockController.get_timestamp(operationId), DONE_TIMESTAMP);
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
        assertEq(timelockController.is_operation(operationId), true);
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
        assertEq(timelockController.is_operation(operationId), true);
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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
        bytes32 slot = bytes32(uint256(1337));
        bytes32 value = bytes32(uint256(6699));
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

    // /*//////////////////////////////////////////////////////////////
    //                           BATCH TESTS
    // //////////////////////////////////////////////////////////////*/

    // function testBatchComplete() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     assertEq(counter.number(), 0);

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     assertEq(counter.number(), 1);
    // }

    // function testBatchOperationAlreadyScheduled() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(0);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = new bytes(0);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.startPrank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.expectRevert("TimelockController: operation already scheduled");
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );
    // }

    // function testBatchInsufficientDelay() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(0);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = new bytes(0);

    //     vm.expectRevert("TimelockController: insufficient delay");
    //     vm.prank(PROPOSER_ONE);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY - 1
    //     );
    // }

    // function testBatchEqualAndGreaterMinimumDelay() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(0);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = new bytes(0);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     assertEq(timelockController.is_operation(batchedoperationId), true);

    //     batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         bytes32("1")
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY + 1
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         bytes32("1"),
    //         MIN_DELAY + 1
    //     );

    //     assertEq(timelockController.is_operation(batchedoperationId), true);
    // }

    // function testBatchMinimumDelayUpdate() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(0);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = new bytes(0);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     uint256 operationTimestampBefore = timelockController.get_timestamp(
    //         batchedoperationId
    //     );

    //     // Set a new delay value
    //     vm.prank(address(timelockController));
    //     timelockController.update_delay(MIN_DELAY + 31 days);

    //     // New delay value should only apply on future operations, not existing ones
    //     uint256 operationTimestampAfter = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestampAfter, operationTimestampBefore);
    // }

    // function testBatchOperationIsNotReady() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(0);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = new bytes(0);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY - 2 days);

    //     vm.expectRevert("TimelockController: operation is not ready");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    // }

    // function testBatchPredecessorNotExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.startPrank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     bytes32 batchedoperationId2 = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         batchedoperationId,
    //         EMPTY_SALT
    //     );

    //     // Schedule dependent job
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId2,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             batchedoperationId,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         batchedoperationId,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );
    //     vm.stopPrank();

    //     // Check that executing the dependent job reverts
    //     vm.warp(block.timestamp + MIN_DELAY + 2 days);
    //     vm.expectRevert("TimelockController: missing dependency");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         batchedoperationId,
    //         EMPTY_SALT
    //     );
    // }

    // function testBatchPredecessorNotScheduled() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     vm.startPrank(PROPOSER_ONE);

    //     // Prepare predecessor job
    //     bytes32 operationOneID = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     bytes32 operationOneID2 = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         operationOneID,
    //         EMPTY_SALT
    //     );

    //     // Schedule dependent job
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             operationOneID2,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             operationOneID,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         operationOneID,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );
    //     vm.stopPrank();

    //     // Check that executing the dependent job reverts
    //     vm.warp(block.timestamp + MIN_DELAY + 2 days);
    //     vm.expectRevert("TimelockController: missing dependency");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         operationOneID,
    //         EMPTY_SALT
    //     );
    // }

    // function testBatchPredecessorInvalid() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     // Prepare invalid predecessor
    //     bytes32 invalidPredecessor = 0xe685571b7e25a4a0391fb8daa09dc8d3fbb3382504525f89a2334fbbf8f8e92c;

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         invalidPredecessor,
    //         EMPTY_SALT
    //     );

    //     // Schedule dependent job
    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             invalidPredecessor,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         invalidPredecessor,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     // Check that executing the dependent job reverts
    //     vm.warp(block.timestamp + MIN_DELAY + 2 days);
    //     vm.expectRevert("TimelockController: missing dependency");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         invalidPredecessor,
    //         EMPTY_SALT
    //     );
    // }

    // function testBatchTargetRevert() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.mockRevert.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     // Schedule a job where one target will revert
    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY + 2 days);
    //     vm.expectRevert("Transaction reverted");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    // }

    // function testBatchPredecessorMultipleNotExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     // Schedule predecessor job
    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     payloads[0] = abi.encodeWithSelector(Counter.setNumber.selector, 1);

    //     // Schedule dependent job
    //     vm.prank(PROPOSER_ONE);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         batchedoperationId,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     // Check that executing the dependent job reverts
    //     vm.warp(block.timestamp + MIN_DELAY + 2 days);
    //     vm.expectRevert("TimelockController: missing dependency");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         batchedoperationId,
    //         EMPTY_SALT
    //     );
    // }

    // function testBatchCancelFinished() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY + 1);
    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    //     vm.prank(PROPOSER_ONE);
    //     vm.expectRevert("TimelockController: operation cannot be cancelled");
    //     timelockController.cancel(batchedoperationId);
    // }

    // function testBatchPendingIfNotYetExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     bool is_operation_pending = timelockController.is_operation_pending(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_pending, true);
    // }

    // function testBatchPendingIfExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);
    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     bool is_operation_pending = timelockController.is_operation_pending(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_pending, false);
    // }

    // function testBatchReadyOnTheExecutionTime() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     bool is_operation_ready = timelockController.is_operation_ready(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_ready, true);
    // }

    // function testBatchReadyAfterTheExecutionTime() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY + 1 days);

    //     bool is_operation_ready = timelockController.is_operation_ready(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_ready, true);
    // }

    // function testBatchReadyBeforeTheExecutionTime() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY - 1 days);

    //     bool is_operation_ready = timelockController.is_operation_ready(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_ready, false);
    // }

    // function testBatchHasBeenExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);
    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     bool is_operation_ready = timelockController.is_operation_ready(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_ready, false);

    //     bool is_operation_done = timelockController.is_operation_done(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_done, true);
    // }

    // function testBatchHasNotBeenExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     bool is_operation_done = timelockController.is_operation_done(
    //         batchedoperationId
    //     );
    //     assertEq(is_operation_done, false);
    // }

    // function testBatchTimestampHasNotBeenExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestamp, block.timestamp + MIN_DELAY);
    // }

    // function testBatchTimestampHasBeenExecuted() public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);
    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestamp, DONE_TIMESTAMP);
    // }

    // function testFuzzBatchValue(uint256 amount) public {
    //     address[] memory targets = new address[](1);
    //     targets[0] = address(counter);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = amount;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

    //     deal(address(timelockController), amount);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestamp, DONE_TIMESTAMP);
    //     assertEq(address(counter).balance, values[0]);
    // }

    // function testBatchERC1155() public {
    //     ERC1155Mock erc1155 = new ERC1155Mock("");
    //     erc1155.mint(address(timelockController), 1, 1, new bytes(0));

    //     assertEq(erc1155.balanceOf(address(timelockController), 1), 1);

    //     address[] memory targets = new address[](1);
    //     targets[0] = address(erc1155);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(
    //         ERC1155Mock.burn.selector,
    //         address(timelockController),
    //         1,
    //         1
    //     );

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestamp, DONE_TIMESTAMP);
    //     assertEq(erc1155.balanceOf(address(timelockController), 1), 0);
    // }

    // function testBatchERC721() public {
    //     ERC721Mock erc721 = new ERC721Mock("SYMBOL", "SML");
    //     erc721.mint(address(timelockController), 1);

    //     assertEq(erc721.balanceOf(address(timelockController)), 1);

    //     address[] memory targets = new address[](1);
    //     targets[0] = address(erc721);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(ERC721Mock.burn.selector, 1);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestamp, DONE_TIMESTAMP);
    //     assertEq(erc721.balanceOf(address(timelockController)), 0);
    // }

    // /*//////////////////////////////////////////////////////////////
    //                        SANITY CHECKS TESTS
    // //////////////////////////////////////////////////////////////*/

    // function testReturnsLaterMinimumDelayForCalls() public {
    //     uint256 newMinDelay = 31 days;
    //     _laterDelay(newMinDelay);
    //     uint256 minDelay = timelockController.get_minimum_delay();
    //     assertEq(minDelay, newMinDelay);
    // }

    // function testInvalidOperation() public {
    //     bool is_operation = timelockController.is_operation(bytes32("non-op"));
    //     assertEq(is_operation, false);
    // }

    // // Hash calculation
    // function testHashOperationBatch() public {
    //     address[] memory targets = new address[](2);
    //     targets[0] = address(this);
    //     targets[1] = address(this);

    //     uint256[] memory values = new uint256[](2);
    //     values[0] = 0;
    //     values[1] = 1;

    //     bytes[] memory payloads = new bytes[](2);
    //     payloads[0] = abi.encodeWithSelector(
    //         this.testHashOperationBatch.selector
    //     );
    //     payloads[1] = abi.encodeWithSelector(
    //         this.testHashOperationBatch.selector
    //     );

    //     bytes32 hashedOperation = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    //     bytes32 expectedHash = keccak256(
    //         abi.encode(targets, values, payloads, NO_PREDECESSOR, EMPTY_SALT)
    //     );
    //     assertEq(hashedOperation, expectedHash);
    // }

    // function testHashOperation() public {
    //     address target = address(this);
    //     uint256 amount = 1;
    //     bytes memory payload = abi.encodeWithSelector(
    //         this.testHashOperationBatch.selector
    //     );

    //     bytes32 hashedOperation = timelockController.hash_operation(
    //         target,
    //         amount,
    //         payload,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    //     bytes32 expectedHash = keccak256(
    //         abi.encode(target, amount, payload, NO_PREDECESSOR, EMPTY_SALT)
    //     );
    //     assertEq(hashedOperation, expectedHash);
    // }

    // // TODO: Add NFTs tests

    // /*//////////////////////////////////////////////////////////////
    //                          PERMISSION TESTS
    // //////////////////////////////////////////////////////////////*/

    // // Timelock

    // function testRevertWhenNotTimelock() public {
    //     vm.expectRevert("TimelockController: caller must be timelock");
    //     vm.prank(STRANGER);
    //     timelockController.update_delay(3 days);
    // }

    // // Admin

    // function testAdminCantBatchSchedule() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(ADMIN);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );
    // }

    // function testAdminCantSchedule() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(ADMIN);
    //     timelockController.schedule(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );
    // }

    // function testAdminCantBatchExecute() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(ADMIN);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    // }

    // function testAdminCantExecute() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(ADMIN);
    //     timelockController.execute(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    // }

    // function testAdminCantCancel() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(ADMIN);
    //     timelockController.cancel(EMPTY_SALT);
    // }

    // // Proposer

    // function testProposerCanBatchSchedule() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.prank(PROPOSER_ONE);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.prank(PROPOSER_TWO);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         bytes32("1"),
    //         MIN_DELAY
    //     );
    // }

    // function testProposerCanSchedule() public {
    //     vm.prank(PROPOSER_ONE);
    //     timelockController.schedule(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.prank(PROPOSER_TWO);
    //     timelockController.schedule(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         bytes32("1"),
    //         MIN_DELAY
    //     );
    // }

    // function testProposerCantBatchExecute() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(PROPOSER_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(PROPOSER_TWO);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         bytes32("1")
    //     );
    // }

    // function testProposerCantExecute() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(PROPOSER_ONE);
    //     timelockController.execute(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(PROPOSER_TWO);
    //     timelockController.execute(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         bytes32("1")
    //     );
    // }

    // function testProposerCanCancel() public {
    //     vm.expectRevert("TimelockController: operation cannot be cancelled");
    //     vm.prank(PROPOSER_ONE);
    //     timelockController.cancel(EMPTY_SALT);

    //     vm.expectRevert("TimelockController: operation cannot be cancelled");
    //     vm.prank(PROPOSER_TWO);
    //     timelockController.cancel(EMPTY_SALT);
    // }

    // // Executor

    // function testExecutorCantBatchSchedule() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(EXECUTOR_TWO);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         bytes32("1"),
    //         MIN_DELAY
    //     );
    // }

    // function testExecutorCantSchedule() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.schedule(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(EXECUTOR_TWO);
    //     timelockController.schedule(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         bytes32("1"),
    //         MIN_DELAY
    //     );
    // }

    // function testExecutorCanBatchExecute() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.expectRevert("TimelockController: operation is not ready");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.expectRevert("TimelockController: operation is not ready");
    //     vm.prank(EXECUTOR_TWO);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         bytes32("1")
    //     );
    // }

    // function testExecutorCanExecute() public {
    //     vm.expectRevert("TimelockController: operation is not ready");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.execute(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.expectRevert("TimelockController: operation is not ready");
    //     vm.prank(EXECUTOR_TWO);
    //     timelockController.execute(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         bytes32("1")
    //     );
    // }

    // function testExecutorCantCancel() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(EXECUTOR_ONE);
    //     timelockController.cancel(EMPTY_SALT);

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(EXECUTOR_TWO);
    //     timelockController.cancel(EMPTY_SALT);
    // }

    // // Stanger

    // function testStrangerCantBatchSchedule() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(STRANGER);
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );
    // }

    // function testStrangerCantSchedule() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(STRANGER);
    //     timelockController.schedule(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );
    // }

    // function testStrangerCantBatchExecute() public {
    //     address[] memory targets = new address[](0);
    //     uint256[] memory values = new uint256[](0);
    //     bytes[] memory payloads = new bytes[](0);

    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(STRANGER);
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    // }

    // function testStrangerCantExecute() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(STRANGER);
    //     timelockController.execute(
    //         address(0),
    //         0,
    //         new bytes(0),
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );
    // }

    // function testStrangerCantCancel() public {
    //     vm.expectRevert("AccessControl: account is missing role");
    //     vm.prank(STRANGER);
    //     timelockController.cancel(EMPTY_SALT);
    // }

    // // TODO: Move this somewhere in correct place
    // function testCancellerCanCancelOperation() public {
    //     bytes32 operationId = _cancelOperation();

    //     vm.prank(PROPOSER_ONE);
    //     vm.expectEmit(true, false, false, false);
    //     emit ITimelockController.Cancelled(operationId);
    //     timelockController.cancel(operationId);
    //     assertTrue(!timelockController.is_operation(operationId));
    // }

    // function testOperationERC721() public {
    //     ERC721Mock erc721 = new ERC721Mock("SYMBOL", "SML");
    //     erc721.mint(address(timelockController), 1);

    //     assertEq(erc721.balanceOf(address(timelockController)), 1);

    //     address[] memory targets = new address[](1);
    //     targets[0] = address(erc721);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(ERC721Mock.burn.selector, 1);

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestamp, DONE_TIMESTAMP);
    //     assertEq(erc721.balanceOf(address(timelockController)), 0);
    // }

    // function testOperationERC1155() public {
    //     ERC1155Mock erc1155 = new ERC1155Mock("");
    //     erc1155.mint(address(timelockController), 1, 1, new bytes(0));

    //     assertEq(erc1155.balanceOf(address(timelockController), 1), 1);

    //     address[] memory targets = new address[](1);
    //     targets[0] = address(erc1155);

    //     uint256[] memory values = new uint256[](1);
    //     values[0] = 0;

    //     bytes[] memory payloads = new bytes[](1);
    //     payloads[0] = abi.encodeWithSelector(
    //         ERC1155Mock.burn.selector,
    //         address(timelockController),
    //         1,
    //         1
    //     );

    //     bytes32 batchedoperationId = timelockController.hash_operation_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     vm.prank(PROPOSER_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallScheduled(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i],
    //             NO_PREDECESSOR,
    //             MIN_DELAY
    //         );
    //     }
    //     timelockController.schedule_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     vm.prank(EXECUTOR_ONE);
    //     for (uint256 i = 0; i < targets.length; ++i) {
    //         vm.expectEmit(true, true, false, true);
    //         emit ITimelockController.CallExecuted(
    //             batchedoperationId,
    //             i,
    //             targets[i],
    //             values[i],
    //             payloads[i]
    //         );
    //     }
    //     timelockController.execute_batch(
    //         targets,
    //         values,
    //         payloads,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         batchedoperationId
    //     );
    //     assertEq(operationTimestamp, DONE_TIMESTAMP);
    //     assertEq(erc1155.balanceOf(address(timelockController), 1), 0);
    // }

    // function testFuzzOperationValue(uint256 amount) public {
    //     address target = address(counter);
    //     bytes memory payload = abi.encodeWithSelector(
    //         Counter.increment.selector
    //     );

    //     bytes32 operationId = timelockController.hash_operation(
    //         target,
    //         amount,
    //         payload,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     deal(address(timelockController), amount);

    //     vm.prank(PROPOSER_ONE);
    //     vm.expectEmit(true, true, false, true);
    //     emit ITimelockController.CallScheduled(
    //         operationId,
    //         0,
    //         target,
    //         amount,
    //         payload,
    //         NO_PREDECESSOR,
    //         MIN_DELAY
    //     );
    //     timelockController.schedule(
    //         target,
    //         amount,
    //         payload,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT,
    //         MIN_DELAY
    //     );

    //     vm.warp(block.timestamp + MIN_DELAY);

    //     vm.prank(EXECUTOR_ONE);
    //     vm.expectEmit(true, true, false, true);
    //     emit ITimelockController.CallExecuted(
    //         operationId,
    //         0,
    //         target,
    //         amount,
    //         payload
    //     );
    //     timelockController.execute(
    //         target,
    //         amount,
    //         payload,
    //         NO_PREDECESSOR,
    //         EMPTY_SALT
    //     );

    //     uint256 operationTimestamp = timelockController.get_timestamp(
    //         operationId
    //     );
    //     assertEq(operationTimestamp, DONE_TIMESTAMP);
    //     assertEq(address(counter).balance, amount);
    // }
}

// contract TimelockControllerInvariants is Test {
//     VyperDeployer private vyperDeployer = new VyperDeployer();

//     ITimelockController private timelockController;
//     TimelockControllerHandler private timelockControllerHandler;

//     function setUp() public {
//         address[] memory proposers = new address[](1);
//         proposers[0] = address(this);

//         address[] memory executors = new address[](1);
//         executors[0] = address(this);

//         uint256 minDelay = 2 days;

//         bytes memory args = abi.encode(
//             minDelay,
//             proposers,
//             executors,
//             address(this)
//         );
//         timelockController = ITimelockController(
//             payable(
//                 vyperDeployer.deployContract(
//                     "src/governance/",
//                     "TimelockController",
//                     args
//                 )
//             )
//         );

//         timelockControllerHandler = new TimelockControllerHandler(
//             timelockController,
//             minDelay,
//             proposers,
//             executors,
//             address(this)
//         );

//         // Select the selectors to use for fuzzing.
//         bytes4[] memory selectors = new bytes4[](3);
//         selectors[0] = TimelockControllerHandler.schedule.selector;
//         selectors[1] = TimelockControllerHandler.execute.selector;
//         selectors[2] = TimelockControllerHandler.cancel.selector;

//         // Set the target selector.
//         targetSelector(
//             FuzzSelector({
//                 addr: address(timelockControllerHandler),
//                 selectors: selectors
//             })
//         );

//         // Set the target contract.
//         targetContract(address(timelockControllerHandler));
//     }

//     // Number of pending transactions cannot exceed executed transactions
//     function invariantExecutedLessThanOrEqualToPending() public {
//         assertLe(
//             timelockControllerHandler.execute_count(),
//             timelockControllerHandler.schedule_count()
//         );
//     }

//     // Number of proposals executed must match the count number.
//     function invariantProposalsExecutedMatchCount() public {
//         assertEq(
//             timelockControllerHandler.execute_count(),
//             timelockControllerHandler.counter()
//         );
//     }

//     // Proposals can only be scheduled and executed once
//     function invariantOnceProposalExecution() public {
//         uint256[] memory executed = timelockControllerHandler.getExecuted();
//         // Loop over all executed proposals.
//         for (uint256 i = 0; i < executed.length; ++i) {
//             // Check that the executed proposal cannot be executed again.
//             vm.expectRevert("TimelockController: operation is not ready");
//             timelockController.execute(
//                 address(timelockControllerHandler),
//                 0,
//                 abi.encodeWithSelector(
//                     TimelockControllerHandler.increment.selector
//                 ),
//                 bytes32(""),
//                 bytes32(executed[i])
//             );
//         }
//     }

//     // Sum of number of executed proposals and cancelled proposals must be less or equal to the amount of proposals scheduled.
//     function invariantSumOfProposals() public {
//         assertLe(
//             timelockControllerHandler.cancel_count() +
//                 timelockControllerHandler.execute_count(),
//             timelockControllerHandler.schedule_count()
//         );
//     }

//     // Executed proposals cannot be cancelled
//     function invariantExecutedProposalCancellation() public {
//         uint256[] memory executed = timelockControllerHandler.getExecuted();
//         // Loop over all executed proposals.
//         for (uint256 i = 0; i < executed.length; ++i) {
//             // Check that the executed proposal cannot be cancelled.
//             vm.expectRevert(
//                 "TimelockController: operation cannot be cancelled"
//             );
//             timelockController.cancel(bytes32(executed[i]));
//         }
//     }

//     // Executing a proposal that has been cancelled is not possible
//     function invariantExecutingCancelledProposal() public {
//         uint256[] memory cancelled = timelockControllerHandler.getCancelled();
//         // Loop over all cancelled proposals.
//         for (uint256 i = 0; i < cancelled.length; ++i) {
//             // Check that the cancelled proposal cannot be executed.
//             vm.expectRevert("TimelockController: operation is not ready");
//             timelockController.execute(
//                 address(timelockControllerHandler),
//                 0,
//                 abi.encodeWithSelector(
//                     TimelockControllerHandler.increment.selector
//                 ),
//                 bytes32(""),
//                 bytes32(cancelled[i])
//             );
//         }
//     }

//     // Executing a proposal that is not ready is not possible
//     function invariantExecutingNotReadyProposal() public {
//         uint256[] memory pending = timelockControllerHandler.getPending();
//         // Loop over all pending proposals.
//         for (uint256 i = 0; i < pending.length; ++i) {
//             // Check that the pending proposal cannot be executed.
//             vm.expectRevert("TimelockController: operation is not ready");
//             timelockController.execute(
//                 address(timelockControllerHandler),
//                 0,
//                 abi.encodeWithSelector(
//                     TimelockControllerHandler.increment.selector
//                 ),
//                 bytes32(""),
//                 bytes32(pending[i])
//             );
//         }
//     }
// }

// contract TimelockControllerHandler is Test {
//     ITimelockController private timelockController;
//     uint256 private minDelay;
//     address private admin;
//     address private proposer;
//     address private executor;

//     uint256 public counter;

//     uint256 public schedule_count;
//     uint256 public execute_count;
//     uint256 public cancel_count;

//     uint256[] public pending;
//     uint256[] public executed;
//     uint256[] public cancelled;

//     constructor(
//         ITimelockController timelockController_,
//         uint256 minDelay_,
//         address[] memory proposer_,
//         address[] memory executor_,
//         address admin_
//     ) {
//         timelockController = timelockController_;
//         minDelay = minDelay_;
//         proposer = proposer_[0];
//         executor = executor_[0];
//         admin = admin_;
//     }

//     function schedule(uint256 random) external {
//         vm.prank(proposer);
//         timelockController.schedule(
//             address(this),
//             0,
//             abi.encodeWithSelector(this.increment.selector),
//             bytes32(""),
//             bytes32(random),
//             minDelay
//         );

//         pending.push(random);
//         schedule_count++;
//     }

//     function execute(uint256 random) external {
//         if (pending.length == 0 || schedule_count == 0) {
//             return;
//         }

//         uint256 identifier = random % pending.length;
//         uint256 operation = pending[identifier];

//         // Advance time to make the proposal ready.
//         vm.warp(block.timestamp + minDelay);

//         vm.prank(executor);
//         timelockController.execute(
//             address(this),
//             0,
//             abi.encodeWithSelector(this.increment.selector),
//             bytes32(""),
//             bytes32(operation)
//         );

//         delete pending[identifier];
//         executed.push(operation);

//         execute_count++;
//     }

//     function cancel(uint256 random) external {
//         if (pending.length == 0 || schedule_count == 0) {
//             return;
//         }

//         uint256 identifier = random % pending.length;
//         uint256 operation = pending[identifier];

//         vm.prank(proposer);
//         timelockController.cancel(bytes32(operation));

//         delete pending[identifier];
//         cancelled.push(operation);

//         cancel_count++;
//     }

//     function getExecuted() external view returns (uint256[] memory) {
//         return executed;
//     }

//     function getCancelled() external view returns (uint256[] memory) {
//         return cancelled;
//     }

//     function getPending() external view returns (uint256[] memory) {
//         return pending;
//     }

//     function increment() external {
//         counter++;
//     }
// }
