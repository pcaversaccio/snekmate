// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {TimelockController} from "openzeppelin/governance/TimelockController.sol";

contract TimelockControllerTest is Test {
    uint256 internal constant MIN_DELAY = 2 days;
    uint256 internal constant DONE_TIMESTAMP = 1;
    uint256 internal constant DELAY_ONE_MONTH = 31 days;
    uint256 internal constant DELAY_TWO_DAYS = 48 hours;

    address private immutable ADMIN = address(this);
    address private constant PROPOSER_ONE = address(0x1);
    address private constant PROPOSER_TWO = address(0x2);
    address private constant EXECUTOR_ONE = address(0x3);
    address private constant EXECUTOR_TWO = address(0x4);
    address private constant STRANGER = address(0x99);

    bytes32 internal constant NO_PREDECESSOR = bytes32("");
    bytes32 internal constant EMPTY_SALT = bytes32("");

    address[2] private PROPOSERS;
    address[2] private EXECUTORS;

    Call[] internal calls;

    Counter private counter;

    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    VyperDeployer private vyperDeployer = new VyperDeployer();

    TimelockController private timelockController;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        PROPOSERS[0] = PROPOSER_ONE;
        PROPOSERS[1] = PROPOSER_TWO;

        EXECUTORS[0] = EXECUTOR_ONE;
        EXECUTORS[1] = EXECUTOR_TWO;

        address[] memory proposers = new address[](2);
        proposers[0] = PROPOSER_ONE;
        proposers[1] = PROPOSER_TWO;

        address[] memory executors = new address[](2);
        executors[0] = EXECUTOR_ONE;
        executors[1] = EXECUTOR_TWO;

        bytes memory args = abi.encode(MIN_DELAY, proposers, executors, ADMIN);
        timelockController = TimelockController(
            payable(
                vyperDeployer.deployContract(
                    "src/governance/",
                    "TimelockController",
                    args
                )
            )
        );

        counter = new Counter(address(timelockController));

        calls.push(
            Call({
                target: address(counter),
                value: 0,
                data: abi.encodeWithSelector(Counter.increment.selector)
            })
        );
        calls.push(
            Call({
                target: address(counter),
                value: 0,
                data: abi.encodeWithSelector(Counter.setNumber.selector, 10)
            })
        );
    }

    function checkRoleNotSetForAddresses(
        TimelockController timelock,
        bytes32 role,
        address[2] storage addresses
    ) internal {
        for (uint256 i = 0; i < addresses.length; ++i) {
            assertFalse(timelock.hasRole(role, addresses[i]));
        }
    }

    function testInitialSetup() public {
        assertEq(
            timelockController.hasRole(
                timelockController.DEFAULT_ADMIN_ROLE(),
                address(this)
            ),
            true
        );

        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.DEFAULT_ADMIN_ROLE(),
            PROPOSERS
        );
        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.DEFAULT_ADMIN_ROLE(),
            EXECUTORS
        );

        assertEq(
            timelockController.hasRole(
                timelockController.PROPOSER_ROLE(),
                PROPOSER_ONE
            ),
            true
        );
        assertEq(
            timelockController.hasRole(
                timelockController.PROPOSER_ROLE(),
                PROPOSER_TWO
            ),
            true
        );

        assertFalse(
            timelockController.hasRole(
                timelockController.PROPOSER_ROLE(),
                ADMIN
            )
        );

        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.PROPOSER_ROLE(),
            EXECUTORS
        );

        assertEq(
            timelockController.hasRole(
                timelockController.EXECUTOR_ROLE(),
                EXECUTOR_ONE
            ),
            true
        );
        assertEq(
            timelockController.hasRole(
                timelockController.EXECUTOR_ROLE(),
                EXECUTOR_TWO
            ),
            true
        );
        assertFalse(
            timelockController.hasRole(
                timelockController.EXECUTOR_ROLE(),
                ADMIN
            )
        );
        checkRoleNotSetForAddresses(
            timelockController,
            timelockController.EXECUTOR_ROLE(),
            PROPOSERS
        );
        assertEq(timelockController.getMinDelay(), MIN_DELAY);

        // TODO: Add event emit checks.
    }

    function testHashesBatchedOperationsCorrectly() public {
        address[] memory targets = new address[](2);
        targets[0] = address(this);
        targets[1] = address(this);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 1;

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(
            this.testHashesBatchedOperationsCorrectly.selector
        );
        payloads[1] = abi.encodeWithSelector(
            this.testHashesBatchedOperationsCorrectly.selector
        );

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        bytes32 hashedOperation = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            predecessor,
            salt
        );
        bytes32 expectedHash = keccak256(
            abi.encode(targets, values, payloads, predecessor, salt)
        );
        assertEq(hashedOperation, expectedHash);
    }

    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    function testRevertWhenNotAdminRole() public {
        vm.expectRevert("TimelockController: unauthorized");
        vm.prank(STRANGER);
        timelockController.updateDelay(3 days);
    }

    function testUpdatesMinDelay() public {
        address target = address(timelockController);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            timelockController.updateDelay.selector,
            MIN_DELAY
        );

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        vm.prank(PROPOSER_ONE);
        timelockController.schedule(
            target,
            value,
            data,
            predecessor,
            salt,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        timelockController.execute(target, value, data, predecessor, salt);

        uint256 minDelay = timelockController.getMinDelay();
        assertEq(minDelay, 2 days);
    }

    function testRevertWhenLessThanMinDelay() public {
        address target = address(timelockController);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            timelockController.updateDelay.selector,
            0
        );

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.schedule(
            target,
            value,
            data,
            predecessor,
            salt,
            MIN_DELAY - 1
        );
    }

    function testUpdatesDelayAtLeastMinDelay() public {
        vm.prank(address(timelockController));
        timelockController.updateDelay(0); // set min delay to 0

        address target = address(timelockController);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            timelockController.updateDelay.selector,
            MIN_DELAY
        );

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        vm.prank(PROPOSER_ONE);
        timelockController.schedule(
            target,
            value,
            data,
            NO_PREDECESSOR,
            EMPTY_SALT,
            1
        );

        vm.warp(block.timestamp + 1);

        vm.prank(EXECUTOR_ONE);
        timelockController.execute(target, value, data, predecessor, salt);

        uint256 minDelay = timelockController.getMinDelay();
        assertEq(minDelay, MIN_DELAY);
    }

    function testRevertWhenNotProposer() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function _scheduleBatchedOperation()
        internal
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        )
    {
        targets = new address[](calls.length);
        values = new uint256[](calls.length);
        payloads = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; ++i) {
            targets[i] = calls[i].target;
            values[i] = calls[i].value;
            payloads[i] = calls[i].data;
        }
    }

    function testProposerCanBatchSchedule() public {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        ) = _scheduleBatchedOperation();

        bytes32 batchedOperationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        assertEq(timelockController.isOperation(batchedOperationID), false);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        assertEq(timelockController.isOperation(batchedOperationID), true);
    }

    function testAdminCantBatchSchedule() public {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        ) = _scheduleBatchedOperation();

        bytes32 batchedOperationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        assertEq(timelockController.isOperation(batchedOperationID), false);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        assertEq(timelockController.isOperation(batchedOperationID), false);
    }

    function testRevertWhenScheduleIfOperationScheduled() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.startPrank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.expectRevert("TimelockController: operation already scheduled");
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testRevertWhenScheduleIfDelayLessThanMinDelay() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY - 1
        );
    }

    function testProposerCanScheduleOperation() public {
        bytes32 operationID = _scheduleOperation(PROPOSER_ONE);
        assertTrue(timelockController.isOperation(operationID));
    }

    function testAdminCantScheduleOperation() public {
        vm.expectRevert("AccessControl: account is missing role");
        bytes32 operationID = _scheduleOperation(ADMIN);
        assertFalse(timelockController.isOperation(operationID));
    }

    function _scheduleOperation(
        address proposer
    ) internal returns (bytes32 operationID) {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.startPrank(proposer);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function _laterDelay() internal {
        vm.prank(address(timelockController));
        timelockController.updateDelay(31 days);
    }

    function testReturnsLaterMinDelayForCalls() public {
        _laterDelay();
        uint256 minDelay = timelockController.getMinDelay();
        assertEq(minDelay, 31 days);
    }

    function testRevertWhenLaterDelayTooLow() public {
        _laterDelay();

        address[] memory targets = new address[](calls.length);
        uint256[] memory values = new uint256[](calls.length);
        bytes[] memory payloads = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; ++i) {
            targets[i] = calls[i].target;
            values[i] = calls[i].value;
            payloads[i] = calls[i].data;
        }

        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            31 days - 1
        );
    }

    function _scheduleBatchedOperation(
        address proposer,
        uint256 delay
    ) internal {
        address[] memory targets = new address[](calls.length);
        uint256[] memory values = new uint256[](calls.length);
        bytes[] memory payloads = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; ++i) {
            targets[i] = calls[i].target;
            values[i] = calls[i].value;
            payloads[i] = calls[i].data;
        }

        bytes32 batchedOperationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        assertEq(timelockController.isOperation(batchedOperationID), false);

        vm.prank(proposer);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            delay
        );

        assertEq(timelockController.isOperation(batchedOperationID), true);

        uint256 operationTimestamp = timelockController.getTimestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, block.timestamp + delay);
    }

    function testProposerCanBatchScheduleGreaterEqualToLaterMinDelay() public {
        _laterDelay();
        _scheduleBatchedOperation(PROPOSER_ONE, 31 days);
    }

    function testUpdateDelayDoesNotChangeExistingOperationTimestamps() public {
        _laterDelay();

        address[] memory targets = new address[](calls.length);
        uint256[] memory values = new uint256[](calls.length);
        bytes[] memory payloads = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; ++i) {
            targets[i] = calls[i].target;
            values[i] = calls[i].value;
            payloads[i] = calls[i].data;
        }

        bytes32 batchedOperationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            31 days
        );

        uint256 operationTimestampBefore = timelockController.getTimestamp(
            batchedOperationID
        );

        // Set a new delay value
        vm.prank(address(timelockController));
        timelockController.updateDelay(31 days + 1);

        // New delay value should only apply on future operations, not existing ones
        uint256 operationTimestampAfter = timelockController.getTimestamp(
            batchedOperationID
        );
        assertEq(operationTimestampAfter, operationTimestampBefore);
    }

    function testRevertWhenNotExecutor() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testRevertWhenMultipleOperationNotReady() public {
        address[] memory targets = new address[](calls.length);
        uint256[] memory values = new uint256[](calls.length);
        bytes[] memory payloads = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; ++i) {
            targets[i] = calls[i].target;
            values[i] = calls[i].value;
            payloads[i] = calls[i].data;
        }

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY - 2 days);

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testRevertWhenPredecessorOperationNotExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.startPrank(PROPOSER_ONE);

        // Schedule predecessor job
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        bytes32 operationOneID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        // Schedule dependent job
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert(
            "TimelockController: predecessor operation is not done"
        );
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT
        );
    }

    function testRevertWhenPredecessorOperationNotScheduled() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.startPrank(PROPOSER_ONE);

        // Prepare predecessor job
        bytes32 operationOneID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        // Schedule dependent job
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert(
            "TimelockController: predecessor operation is not done"
        );
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT
        );
    }

    function testRevertWhenPredecessorOperationInvalid() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        // Prepare invalid predecessor
        bytes32 invalidPredecessor = 0xe685571b7e25a4a0391fb8daa09dc8d3fbb3382504525f89a2334fbbf8f8e92c;

        // Schedule dependent job
        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            invalidPredecessor,
            EMPTY_SALT,
            MIN_DELAY
        );

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert(
            "TimelockController: predecessor operation is not done"
        );
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            invalidPredecessor,
            EMPTY_SALT
        );
    }

    function testRevertWhenOneTargetReverts() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.mockRevert.selector);

        // Schedule a job where one target will revert
        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: underlying transaction reverted");
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testExecutorCanBatchExecuteOperation() public {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        ) = _scheduleSingleBatchedOperation();

        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        uint256 operationTimestamp = timelockController.getTimestamp(
            operationID
        );

        assertEq(operationTimestamp, DONE_TIMESTAMP);
    }

    function testAdminCantBatchExecuteOperation() public {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        ) = _scheduleSingleBatchedOperation();

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        uint256 operationTimestamp = timelockController.getTimestamp(
            operationID
        );

        assertEq(operationTimestamp, block.timestamp);
    }

    function _scheduleSingleBatchedOperation()
        internal
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        )
    {
        targets = new address[](1);
        targets[0] = address(counter);

        values = new uint256[](1);
        values[0] = 0;

        payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);

        // Schedule batch execution
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
    }

    function testRevertWhenExecutedByNonExecutor() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testRevertWhenSingleOperationNotReady() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY - 2 days);
        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testRevertWhenPredecessorMultipleOperationNotExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        // Schedule predecessor job
        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        bytes32 operationOneID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        payloads[0] = abi.encodeWithSelector(Counter.setNumber.selector, 1);

        // Schedule dependent job
        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT,
            MIN_DELAY
        );

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert(
            "TimelockController: predecessor operation is not done"
        );
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT
        );
    }

    function testRevertWhenTargetReverts() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.mockRevert.selector);

        vm.prank(PROPOSER_ONE);

        // Schedule predecessor job
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: underlying transaction reverted");
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testExecutorCanExecuteOperation() public {
        uint256 num = 10;
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        ) = _executeOperation(num);

        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        uint256 operationTimestamp = timelockController.getTimestamp(
            operationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
        uint256 counterNumber = counter.number();
        assertEq(counterNumber, num);
    }

    function testAdminCantExecuteOperation() public {
        uint256 num = 10;
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        ) = _executeOperation(num);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        uint256 operationTimestamp = timelockController.getTimestamp(
            operationID
        );
        assertEq(operationTimestamp, block.timestamp - MIN_DELAY);
        uint256 counterNumber = counter.number();
        assertEq(counterNumber, 0);
    }

    function _executeOperation(
        uint256 num
    )
        internal
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory payloads
        )
    {
        targets = new address[](1);
        targets[0] = address(counter);

        values = new uint256[](1);
        values[0] = 0;

        payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.setNumber.selector, num);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
    }

    event CallExecuted(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data
    );

    function testEmitsEvent() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;
        bytes32 id = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            predecessor,
            salt
        );

        vm.prank(EXECUTOR_ONE);
        vm.expectEmit(true, true, true, true);
        emit CallExecuted(id, 0, targets[0], values[0], payloads[0]);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testRevertWhenNonCanceller() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_ONE);
        timelockController.cancel(EMPTY_SALT);
    }

    function testRevertWhenFinishedOperation() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        vm.prank(PROPOSER_ONE);
        vm.expectRevert("TimelockController: operation cannot be cancelled");
        timelockController.cancel(operationID);
    }

    function testCancellerCanCancelOperation() public {
        bytes32 operationID = _cancelOperation();

        vm.prank(PROPOSER_ONE);
        timelockController.cancel(operationID);
        assertFalse(timelockController.isOperation(operationID));
    }

    function testAdminCanCancelOperation() public {
        bytes32 operationID = _cancelOperation();

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.cancel(operationID);
        assertTrue(timelockController.isOperation(operationID));
    }

    function _cancelOperation() internal returns (bytes32 operationID) {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testCanReceiveETH() public {
        vm.prank(ADMIN);
        payable(address(timelockController)).transfer(0.5 ether);
        assertEq(address(timelockController).balance, 0.5 ether);
    }

    function testFalseIfNotAnOperation() public {
        bool isOperation = timelockController.isOperation(bytes32("non-op"));
        assertEq(isOperation, false);
    }

    function testTrueIfAnOperation() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperation = timelockController.isOperation(operationID);
        assertEq(isOperation, true);
    }

    function testTrueIfScheduledOperatonNotYetExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationPending = timelockController.isOperationPending(
            operationID
        );
        assertEq(isOperationPending, true);
    }

    function testFalseIfPendingOperationHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationPending = timelockController.isOperationPending(
            operationID
        );
        assertEq(isOperationPending, false);
    }

    function testTrueIfOnTheDelayedExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationReady = timelockController.isOperationReady(
            operationID
        );
        assertEq(isOperationReady, true);
    }

    function testTrueIfAfterTheDelayedExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 1 days);

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationReady = timelockController.isOperationReady(
            operationID
        );
        assertEq(isOperationReady, true);
    }

    function testFalseIfBeforeTheDelayedExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY - 1 days);

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationReady = timelockController.isOperationReady(
            operationID
        );
        assertEq(isOperationReady, false);
    }

    function testFalseIfReadyOperationHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationReady = timelockController.isOperationReady(
            operationID
        );
        assertEq(isOperationReady, false);
    }

    function testFalseItTheOperationHasNotBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationDone = timelockController.isOperationDone(operationID);
        assertEq(isOperationDone, false);
    }

    function testTrueIfOperationHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool isOperationDone = timelockController.isOperationDone(operationID);
        assertEq(isOperationDone, true);
    }

    function testReturnsTheCorrectTimestampIfTheOperationHasNotBeenExecuted()
        public
    {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.getTimestamp(
            operationID
        );
        assertEq(operationTimestamp, block.timestamp + MIN_DELAY);
    }

    function testReturnsOneIfOperationHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.prank(PROPOSER_ONE);
        timelockController.scheduleBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(EXECUTOR_ONE);
        timelockController.executeBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID = timelockController.hashOperationBatch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.getTimestamp(
            operationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
    }
}

contract Counter {
    address private timelock;
    uint256 public number;

    constructor(address _timelock) {
        timelock = _timelock;
    }

    function setNumber(uint256 newNumber) public onlyTimelock {
        number = newNumber;
    }

    function increment() public onlyTimelock {
        number++;
    }

    function mockRevert() public pure {
        revert("Transaction reverted");
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Not timelock controller");
        _;
    }
}

contract TimelockControllerInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    TimelockController private timelockController;
    TimelockControllerHandler private timelockControllerHandler;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        address[] memory proposers = new address[](1);
        proposers[0] = address(this);

        address[] memory executors = new address[](1);
        executors[0] = address(this);

        uint256 minDelay = 2 days;

        bytes memory args = abi.encode(
            minDelay,
            proposers,
            executors,
            address(this)
        );
        timelockController = TimelockController(
            payable(
                vyperDeployer.deployContract(
                    "src/governance/",
                    "TimelockController",
                    args
                )
            )
        );

        timelockControllerHandler = new TimelockControllerHandler(
            timelockController,
            minDelay,
            proposers,
            executors,
            address(this)
        );

        // Select the selectors to use for fuzzing.
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = TimelockControllerHandler.schedule.selector;
        selectors[1] = TimelockControllerHandler.execute.selector;
        selectors[2] = TimelockControllerHandler.cancel.selector;

        // Set the target selector.
        targetSelector(
            FuzzSelector({
                addr: address(timelockControllerHandler),
                selectors: selectors
            })
        );

        // Set the target contract.
        targetContract(address(timelockControllerHandler));
    }

    // Number of pending transactions cannot exceed executed transactions
    function invariantExecutedLessThanOrEqualToPending() public {
        assertLe(
            timelockControllerHandler.execute_count(),
            timelockControllerHandler.schedule_count()
        );
    }

    // Number of proposals executed must match the count number.
    function invariantProposalsExecutedMatchCount() public {
        assertEq(
            timelockControllerHandler.execute_count(),
            timelockControllerHandler.counter()
        );
    }

    // Proposals can only be scheduled and executed once
    function invariantOnceProposalExecution() public {
        uint256[] memory executed = timelockControllerHandler.getExecuted();
        // Loop over all executed proposals.
        for (uint256 i = 0; i < executed.length; ++i) {
            // Check that the executed proposal cannot be executed again.
            vm.expectRevert("TimelockController: operation is not ready");
            timelockController.execute(
                address(timelockControllerHandler),
                0,
                abi.encodeWithSelector(
                    TimelockControllerHandler.increment.selector
                ),
                bytes32(""),
                bytes32(executed[i])
            );
        }
    }

    // Sum of number of executed proposals and cancelled proposals must be less or equal to the amount of proposals scheduled.
    function invariantSumOfProposals() public {
        assertLe(
            timelockControllerHandler.cancel_count() +
                timelockControllerHandler.execute_count(),
            timelockControllerHandler.schedule_count()
        );
    }

    // Executed proposals cannot be cancelled
    function invariantExecutedProposalCancellation() public {
        uint256[] memory executed = timelockControllerHandler.getExecuted();
        // Loop over all executed proposals.
        for (uint256 i = 0; i < executed.length; ++i) {
            // Check that the executed proposal cannot be cancelled.
            vm.expectRevert(
                "TimelockController: operation cannot be cancelled"
            );
            timelockController.cancel(bytes32(executed[i]));
        }
    }

    // Executing a proposal that has been cancelled is not possible
    function invariantExecutingCancelledProposal() public {
        uint256[] memory cancelled = timelockControllerHandler.getCancelled();
        // Loop over all cancelled proposals.
        for (uint256 i = 0; i < cancelled.length; ++i) {
            // Check that the cancelled proposal cannot be executed.
            vm.expectRevert("TimelockController: operation is not ready");
            timelockController.execute(
                address(timelockControllerHandler),
                0,
                abi.encodeWithSelector(
                    TimelockControllerHandler.increment.selector
                ),
                bytes32(""),
                bytes32(cancelled[i])
            );
        }
    }

    // Executing a proposal that is not ready is not possible
    function invariantExecutingNotReadyProposal() public {
        uint256[] memory pending = timelockControllerHandler.getPending();
        // Loop over all pending proposals.
        for (uint256 i = 0; i < pending.length; ++i) {
            // Check that the pending proposal cannot be executed.
            vm.expectRevert("TimelockController: operation is not ready");
            timelockController.execute(
                address(timelockControllerHandler),
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
    TimelockController private timelockController;
    uint256 private minDelay;
    address private admin;
    address private proposer;
    address private executor;

    uint256 public counter;

    uint256 public schedule_count;
    uint256 public execute_count;
    uint256 public cancel_count;

    uint256[] public pending;
    uint256[] public executed;
    uint256[] public cancelled;

    constructor(
        TimelockController timelockController_,
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
        vm.prank(proposer);
        timelockController.schedule(
            address(this),
            0,
            abi.encodeWithSelector(this.increment.selector),
            bytes32(""),
            bytes32(random),
            minDelay
        );

        pending.push(random);
        schedule_count++;
    }

    function execute(uint256 random) external {
        if (pending.length == 0 || schedule_count == 0) {
            return;
        }

        uint256 identifier = random % pending.length;
        uint256 operation = pending[identifier];

        // Advance time to make the proposal ready.
        vm.warp(block.timestamp + minDelay);

        vm.prank(executor);
        timelockController.execute(
            address(this),
            0,
            abi.encodeWithSelector(this.increment.selector),
            bytes32(""),
            bytes32(operation)
        );

        delete pending[identifier];
        executed.push(operation);

        execute_count++;
    }

    function cancel(uint256 random) external {
        if (pending.length == 0 || schedule_count == 0) {
            return;
        }

        uint256 identifier = random % pending.length;
        uint256 operation = pending[identifier];

        vm.prank(proposer);
        timelockController.cancel(bytes32(operation));

        delete pending[identifier];
        cancelled.push(operation);

        cancel_count++;
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
