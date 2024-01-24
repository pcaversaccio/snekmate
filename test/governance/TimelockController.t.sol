// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {ERC1155} from "openzeppelin/token/ERC1155/ERC1155.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";

import {ITimelockController} from "./interfaces/ITimelockController.sol";

contract TimelockControllerTest is Test {
    uint256 internal constant MIN_DELAY = 2 days;
    uint256 internal constant DONE_TIMESTAMP = 1;

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

    Counter private counter;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    ITimelockController private timelockController;

    /*//////////////////////////////////////////////////////////////
                                 SET UP
    //////////////////////////////////////////////////////////////*/

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
        timelockController = ITimelockController(
            payable(
                vyperDeployer.deployContract(
                    "src/governance/",
                    "TimelockController",
                    args
                )
            )
        );

        counter = new Counter(address(timelockController));
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
        assertEq(timelockController.get_minimum_delay(), MIN_DELAY);
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function checkRoleNotSetForAddresses(
        ITimelockController timelock,
        bytes32 role,
        address[2] storage addresses
    ) internal {
        for (uint256 i = 0; i < addresses.length; ++i) {
            assertFalse(timelock.hasRole(role, addresses[i]));
        }
    }

    function _laterDelay(uint256 newMinDelay) internal {
        vm.startPrank(address(timelockController));
        vm.expectEmit();
        emit ITimelockController.MinimumDelayChange(
            timelockController.get_minimum_delay(),
            newMinDelay
        );
        timelockController.update_delay(newMinDelay);
        vm.stopPrank();
    }

    function _cancelOperation() internal returns (bytes32 operationID) {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
        operationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    /*//////////////////////////////////////////////////////////////
                            OPERATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testOperationComplete() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        assertEq(counter.number(), 0);

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        vm.prank(EXECUTOR_ONE);
        vm.expectEmit();
        emit ITimelockController.CallExecuted(
            operationID,
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

        assertEq(counter.number(), 1);
    }

    function testOperationAlreadyScheduled() public {
        address target = address(0);
        uint256 amount = 0;
        bytes memory payload = bytes("");

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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
    }

    function testOperationInsufficientDelay() public {
        address target = address(0);
        uint256 amount = 0;
        bytes memory payload = bytes("");

        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.schedule(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY - 1
        );
    }

    function testOperationEqualAndGreaterMinDelay() public {
        address target = address(0);
        uint256 amount = 0;
        bytes memory payload = bytes("");

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        assertEq(timelockController.is_operation(operationID), true);

        operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            bytes32("1")
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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
            bytes32("1"),
            MIN_DELAY + 1
        );

        assertEq(timelockController.is_operation(operationID), true);
    }

    function testOperationMinDelayUpdate() public {
        address target = address(0);
        uint256 amount = 0;
        bytes memory payload = bytes("");

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        uint256 operationTimestampBefore = timelockController.get_timestamp(
            operationID
        );

        // Set a new delay value
        vm.prank(address(timelockController));
        timelockController.update_delay(MIN_DELAY + 31 days);

        // New delay value should only apply on future operations, not existing ones
        uint256 operationTimestampAfter = timelockController.get_timestamp(
            operationID
        );
        assertEq(operationTimestampAfter, operationTimestampBefore);
    }

    function testOperationOperationIsNotReady() public {
        address target = address(0);
        uint256 amount = 0;
        bytes memory payload = bytes("");

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        vm.warp(block.timestamp + MIN_DELAY - 2 days);

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testOperationPredecessorNotExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        bytes32 operationID2 = timelockController.hash_operation(
            target,
            amount,
            payload,
            operationID,
            EMPTY_SALT
        );

        // Schedule dependent job
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID2,
            0,
            target,
            amount,
            payload,
            operationID,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            operationID,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);

        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload,
            operationID,
            EMPTY_SALT
        );
    }

    function testOperationPredecessorNotScheduled() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID1 = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationID2 = timelockController.hash_operation(
            target,
            amount,
            payload,
            operationID1,
            EMPTY_SALT
        );

        // Schedule dependent job
        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID2,
            0,
            target,
            amount,
            payload,
            operationID1,
            MIN_DELAY
        );
        timelockController.schedule(
            target,
            amount,
            payload,
            operationID1,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);

        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload,
            operationID1,
            EMPTY_SALT
        );
    }

    function testOperationPredecessorInvalid() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        // Prepare invalid predecessor
        bytes32 invalidPredecessor = 0xe685571b7e25a4a0391fb8daa09dc8d3fbb3382504525f89a2334fbbf8f8e92c;

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            invalidPredecessor,
            EMPTY_SALT
        );

        // Schedule dependent job
        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        // Check that executing the dependent job reverts
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
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.mockRevert.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        // Schedule a job where one target will revert
        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        vm.warp(block.timestamp + MIN_DELAY + 2 days);

        vm.expectRevert("Transaction reverted");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testOperationPredecessorMultipleNotExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        // Schedule predecessor job
        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        payload = abi.encodeWithSelector(Counter.setNumber.selector, 1);

        // Schedule dependent job
        vm.prank(PROPOSER_ONE);
        timelockController.schedule(
            target,
            amount,
            payload,
            operationID,
            EMPTY_SALT,
            MIN_DELAY
        );

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);

        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            target,
            amount,
            payload,
            operationID,
            EMPTY_SALT
        );
    }

    function testOperationCancelFinished() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        vm.warp(block.timestamp + MIN_DELAY + 1);

        vm.prank(EXECUTOR_ONE);
        vm.expectEmit();
        emit ITimelockController.CallExecuted(
            operationID,
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
        vm.prank(PROPOSER_ONE);
        vm.expectRevert("TimelockController: operation cannot be cancelled");
        timelockController.cancel(operationID);
    }

    function testOperationPendingIfNotYetExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        bool is_operation_pending = timelockController.is_operation_pending(
            operationID
        );
        assertEq(is_operation_pending, true);
    }

    function testOperationPendingIfExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        vm.prank(EXECUTOR_ONE);
        vm.expectEmit();
        emit ITimelockController.CallExecuted(
            operationID,
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

        bool is_operation_pending = timelockController.is_operation_pending(
            operationID
        );
        assertEq(is_operation_pending, false);
    }

    function testOperationReadyOnTheExecutionTime() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        bool is_operation_ready = timelockController.is_operation_ready(
            operationID
        );
        assertEq(is_operation_ready, true);
    }

    function testOperationReadyAfterTheExecutionTime() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        bool is_operation_ready = timelockController.is_operation_ready(
            operationID
        );
        assertEq(is_operation_ready, true);
    }

    function testOperationReadyBeforeTheExecutionTime() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        bool is_operation_ready = timelockController.is_operation_ready(
            operationID
        );
        assertEq(is_operation_ready, false);
    }

    function testOperationHasBeenExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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
        vm.prank(EXECUTOR_ONE);
        vm.expectEmit();
        emit ITimelockController.CallExecuted(
            operationID,
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

        bool is_operation_ready = timelockController.is_operation_ready(
            operationID
        );
        assertEq(is_operation_ready, false);

        bool is_operation_done = timelockController.is_operation_done(
            operationID
        );
        assertEq(is_operation_done, true);
    }

    function testOperationHasNotBeenExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        bool is_operation_done = timelockController.is_operation_done(
            operationID
        );
        assertEq(is_operation_done, false);
    }

    function testOperationTimestampHasNotBeenExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        uint256 operationTimestamp = timelockController.get_timestamp(
            operationID
        );
        assertEq(operationTimestamp, block.timestamp + MIN_DELAY);
    }

    function testOperationTimestampHasBeenExecuted() public {
        address target = address(counter);
        uint256 amount = 0;
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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
        vm.prank(EXECUTOR_ONE);
        vm.expectEmit();
        emit ITimelockController.CallExecuted(
            operationID,
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

        uint256 operationTimestamp = timelockController.get_timestamp(
            operationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
    }

    function testFuzzOperationValue(uint256 amount) public {
        address target = address(counter);
        bytes memory payload = abi.encodeWithSelector(
            Counter.increment.selector
        );

        bytes32 operationID = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        deal(address(timelockController), amount);

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.CallScheduled(
            operationID,
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

        vm.prank(EXECUTOR_ONE);
        vm.expectEmit();
        emit ITimelockController.CallExecuted(
            operationID,
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

        uint256 operationTimestamp = timelockController.get_timestamp(
            operationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
        assertEq(address(counter).balance, amount);
    }

    function testOperationERC1155() public {
        ERC1155Mock erc1155 = new ERC1155Mock("");
        erc1155.mint(address(timelockController), 1, 1, bytes(""));

        assertEq(erc1155.balanceOf(address(timelockController), 1), 1);

        address[] memory targets = new address[](1);
        targets[0] = address(erc1155);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            ERC1155Mock.burn.selector,
            address(timelockController),
            1,
            1
        );

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
        assertEq(erc1155.balanceOf(address(timelockController), 1), 0);
    }

    function testOperationERC721() public {
        ERC721Mock erc721 = new ERC721Mock("SYMBOL", "SML");
        erc721.mint(address(timelockController), 1);

        assertEq(erc721.balanceOf(address(timelockController)), 1);

        address[] memory targets = new address[](1);
        targets[0] = address(erc721);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(ERC721Mock.burn.selector, 1);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
        assertEq(erc721.balanceOf(address(timelockController)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                              BATCH TESTS
    //////////////////////////////////////////////////////////////*/

    function testBatchComplete() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        assertEq(counter.number(), 0);

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        assertEq(counter.number(), 1);
    }

    function testBatchOperationAlreadyScheduled() public {
        address[] memory targets = new address[](1);
        targets[0] = address(0);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = bytes("");

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.expectRevert("TimelockController: operation already scheduled");
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testBatchInsufficientDelay() public {
        address[] memory targets = new address[](1);
        targets[0] = address(0);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = bytes("");

        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY - 1
        );
    }

    function testBatchEqualAndGreaterMinDelay() public {
        address[] memory targets = new address[](1);
        targets[0] = address(0);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = bytes("");

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        assertEq(timelockController.is_operation(batchedOperationID), true);

        batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            bytes32("1")
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY + 1
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            bytes32("1"),
            MIN_DELAY + 1
        );

        assertEq(timelockController.is_operation(batchedOperationID), true);
    }

    function testBatchMinDelayUpdate() public {
        address[] memory targets = new address[](1);
        targets[0] = address(0);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = bytes("");

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        uint256 operationTimestampBefore = timelockController.get_timestamp(
            batchedOperationID
        );

        // Set a new delay value
        vm.prank(address(timelockController));
        timelockController.update_delay(MIN_DELAY + 31 days);

        // New delay value should only apply on future operations, not existing ones
        uint256 operationTimestampAfter = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestampAfter, operationTimestampBefore);
    }

    function testBatchOperationIsNotReady() public {
        address[] memory targets = new address[](1);
        targets[0] = address(0);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = bytes("");

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
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
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testBatchPredecessorNotExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.startPrank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        bytes32 batchedOperationID2 = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            batchedOperationID,
            EMPTY_SALT
        );

        // Schedule dependent job
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID2,
                i,
                targets[i],
                values[i],
                payloads[i],
                batchedOperationID,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            batchedOperationID,
            EMPTY_SALT,
            MIN_DELAY
        );
        vm.stopPrank();

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            batchedOperationID,
            EMPTY_SALT
        );
    }

    function testBatchPredecessorNotScheduled() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        vm.startPrank(PROPOSER_ONE);

        // Prepare predecessor job
        bytes32 operationOneID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bytes32 operationOneID2 = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT
        );

        // Schedule dependent job
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                operationOneID2,
                i,
                targets[i],
                values[i],
                payloads[i],
                operationOneID,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
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
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            operationOneID,
            EMPTY_SALT
        );
    }

    function testBatchPredecessorInvalid() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        // Prepare invalid predecessor
        bytes32 invalidPredecessor = 0xe685571b7e25a4a0391fb8daa09dc8d3fbb3382504525f89a2334fbbf8f8e92c;

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            invalidPredecessor,
            EMPTY_SALT
        );

        // Schedule dependent job
        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                invalidPredecessor,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            invalidPredecessor,
            EMPTY_SALT,
            MIN_DELAY
        );

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            invalidPredecessor,
            EMPTY_SALT
        );
    }

    function testBatchTargetRevert() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.mockRevert.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        // Schedule a job where one target will revert
        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("Transaction reverted");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testBatchPredecessorMultipleNotExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        // Schedule predecessor job
        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        payloads[0] = abi.encodeWithSelector(Counter.setNumber.selector, 1);

        // Schedule dependent job
        vm.prank(PROPOSER_ONE);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            batchedOperationID,
            EMPTY_SALT,
            MIN_DELAY
        );

        // Check that executing the dependent job reverts
        vm.warp(block.timestamp + MIN_DELAY + 2 days);
        vm.expectRevert("TimelockController: missing dependency");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            batchedOperationID,
            EMPTY_SALT
        );
    }

    function testBatchCancelFinished() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        vm.prank(PROPOSER_ONE);
        vm.expectRevert("TimelockController: operation cannot be cancelled");
        timelockController.cancel(batchedOperationID);
    }

    function testBatchPendingIfNotYetExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        bool is_operation_pending = timelockController.is_operation_pending(
            batchedOperationID
        );
        assertEq(is_operation_pending, true);
    }

    function testBatchPendingIfExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool is_operation_pending = timelockController.is_operation_pending(
            batchedOperationID
        );
        assertEq(is_operation_pending, false);
    }

    function testBatchReadyOnTheExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        bool is_operation_ready = timelockController.is_operation_ready(
            batchedOperationID
        );
        assertEq(is_operation_ready, true);
    }

    function testBatchReadyAfterTheExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY + 1 days);

        bool is_operation_ready = timelockController.is_operation_ready(
            batchedOperationID
        );
        assertEq(is_operation_ready, true);
    }

    function testBatchReadyBeforeTheExecutionTime() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY - 1 days);

        bool is_operation_ready = timelockController.is_operation_ready(
            batchedOperationID
        );
        assertEq(is_operation_ready, false);
    }

    function testBatchHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        bool is_operation_ready = timelockController.is_operation_ready(
            batchedOperationID
        );
        assertEq(is_operation_ready, false);

        bool is_operation_done = timelockController.is_operation_done(
            batchedOperationID
        );
        assertEq(is_operation_done, true);
    }

    function testBatchHasNotBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        bool is_operation_done = timelockController.is_operation_done(
            batchedOperationID
        );
        assertEq(is_operation_done, false);
    }

    function testBatchTimestampHasNotBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, block.timestamp + MIN_DELAY);
    }

    function testBatchTimestampHasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
    }

    function testFuzzBatchValue(uint256 amount) public {
        address[] memory targets = new address[](1);
        targets[0] = address(counter);

        uint256[] memory values = new uint256[](1);
        values[0] = amount;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(Counter.increment.selector);

        deal(address(timelockController), amount);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
        assertEq(address(counter).balance, values[0]);
    }

    function testBatchERC1155() public {
        ERC1155Mock erc1155 = new ERC1155Mock("");
        erc1155.mint(address(timelockController), 1, 1, bytes(""));

        assertEq(erc1155.balanceOf(address(timelockController), 1), 1);

        address[] memory targets = new address[](1);
        targets[0] = address(erc1155);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(
            ERC1155Mock.burn.selector,
            address(timelockController),
            1,
            1
        );

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
        assertEq(erc1155.balanceOf(address(timelockController), 1), 0);
    }

    function testBatchERC721() public {
        ERC721Mock erc721 = new ERC721Mock("SYMBOL", "SML");
        erc721.mint(address(timelockController), 1);

        assertEq(erc721.balanceOf(address(timelockController)), 1);

        address[] memory targets = new address[](1);
        targets[0] = address(erc721);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(ERC721Mock.burn.selector, 1);

        bytes32 batchedOperationID = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.prank(PROPOSER_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallScheduled(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i],
                NO_PREDECESSOR,
                MIN_DELAY
            );
        }
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        for (uint256 i = 0; i < targets.length; ++i) {
            vm.expectEmit();
            emit ITimelockController.CallExecuted(
                batchedOperationID,
                i,
                targets[i],
                values[i],
                payloads[i]
            );
        }
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        uint256 operationTimestamp = timelockController.get_timestamp(
            batchedOperationID
        );
        assertEq(operationTimestamp, DONE_TIMESTAMP);
        assertEq(erc721.balanceOf(address(timelockController)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                           SANITY CHECKS TESTS
    //////////////////////////////////////////////////////////////*/

    function testReturnsLaterMinDelayForCalls() public {
        uint256 newMinDelay = 31 days;
        _laterDelay(newMinDelay);
        uint256 minDelay = timelockController.get_minimum_delay();
        assertEq(minDelay, newMinDelay);
    }

    function testCanReceiveEther() public {
        vm.prank(ADMIN);
        payable(address(timelockController)).transfer(0.5 ether);
        assertEq(address(timelockController).balance, 0.5 ether);
    }

    function testInvalidOperation() public {
        bool is_operation = timelockController.is_operation(bytes32("non-op"));
        assertEq(is_operation, false);
    }

    // ERC165 `supportsInterface`

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

    // Hash calculation
    function testHashOperationBatch() public {
        address[] memory targets = new address[](2);
        targets[0] = address(this);
        targets[1] = address(this);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 1;

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(
            this.testHashOperationBatch.selector
        );
        payloads[1] = abi.encodeWithSelector(
            this.testHashOperationBatch.selector
        );

        bytes32 hashedOperation = timelockController.hash_operation_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 expectedHash = keccak256(
            abi.encode(targets, values, payloads, NO_PREDECESSOR, EMPTY_SALT)
        );
        assertEq(hashedOperation, expectedHash);
    }

    function testHashOperation() public {
        address target = address(this);
        uint256 amount = 1;
        bytes memory payload = abi.encodeWithSelector(
            this.testHashOperationBatch.selector
        );

        bytes32 hashedOperation = timelockController.hash_operation(
            target,
            amount,
            payload,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
        bytes32 expectedHash = keccak256(
            abi.encode(target, amount, payload, NO_PREDECESSOR, EMPTY_SALT)
        );
        assertEq(hashedOperation, expectedHash);
    }

    // TODO: Add NFTs tests

    /*//////////////////////////////////////////////////////////////
                             PERMISSION TESTS
    //////////////////////////////////////////////////////////////*/

    // Timelock

    function testRevertWhenNotTimelock() public {
        vm.expectRevert("TimelockController: caller must be timelock");
        vm.prank(STRANGER);
        timelockController.update_delay(3 days);
    }

    // Admin

    function testAdminCantBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testAdminCantSchedule() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.schedule(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testAdminCantBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testAdminCantExecute() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.execute(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testAdminCantCancel() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(ADMIN);
        timelockController.cancel(EMPTY_SALT);
    }

    // Proposer

    function testProposerCanBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.prank(PROPOSER_ONE);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.prank(PROPOSER_TWO);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            bytes32("1"),
            MIN_DELAY
        );
    }

    function testProposerCanSchedule() public {
        vm.prank(PROPOSER_ONE);
        timelockController.schedule(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.prank(PROPOSER_TWO);
        timelockController.schedule(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            bytes32("1"),
            MIN_DELAY
        );
    }

    function testProposerCantBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_ONE);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_TWO);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            bytes32("1")
        );
    }

    function testProposerCantExecute() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_ONE);
        timelockController.execute(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(PROPOSER_TWO);
        timelockController.execute(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            bytes32("1")
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

    // Executor

    function testExecutorCantBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_ONE);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_TWO);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            bytes32("1"),
            MIN_DELAY
        );
    }

    function testExecutorCantSchedule() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_ONE);
        timelockController.schedule(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_TWO);
        timelockController.schedule(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            bytes32("1"),
            MIN_DELAY
        );
    }

    function testExecutorCanBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_TWO);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            bytes32("1")
        );
    }

    function testExecutorCanExecute() public {
        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_ONE);
        timelockController.execute(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT
        );

        vm.expectRevert("TimelockController: operation is not ready");
        vm.prank(EXECUTOR_TWO);
        timelockController.execute(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            bytes32("1")
        );
    }

    function testExecutorCantCancel() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_ONE);
        timelockController.cancel(EMPTY_SALT);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(EXECUTOR_TWO);
        timelockController.cancel(EMPTY_SALT);
    }

    // Stanger

    function testStrangerCantBatchSchedule() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.schedule_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testStrangerCantSchedule() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.schedule(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT,
            MIN_DELAY
        );
    }

    function testStrangerCantBatchExecute() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory payloads = new bytes[](0);

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.execute_batch(
            targets,
            values,
            payloads,
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testStrangerCantExecute() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.execute(
            address(0),
            0,
            bytes(""),
            NO_PREDECESSOR,
            EMPTY_SALT
        );
    }

    function testStrangerCantCancel() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(STRANGER);
        timelockController.cancel(EMPTY_SALT);
    }

    // TODO: Move this somewhere in correct place
    function testCancellerCanCancelOperation() public {
        bytes32 operationID = _cancelOperation();

        vm.prank(PROPOSER_ONE);
        vm.expectEmit();
        emit ITimelockController.Cancelled(operationID);
        timelockController.cancel(operationID);
        assertFalse(timelockController.is_operation(operationID));
    }
}

contract ERC1155Mock is ERC1155 {
    constructor(string memory uri) ERC1155(uri) {}

    function mint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) external {
        _mint(to, id, value, data);
    }

    function burn(address from, uint256 id, uint256 value) external {
        _burn(from, id, value);
    }
}

contract ERC721Mock is ERC721 {
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}

contract Counter {
    address private timelock;
    uint256 public number;

    constructor(address _timelock) {
        timelock = _timelock;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Not timelock controller");
        _;
    }

    function setNumber(uint256 newNumber) external onlyTimelock {
        number = newNumber;
    }

    function increment() external payable onlyTimelock {
        number++;
    }

    function mockRevert() external pure {
        revert("Transaction reverted");
    }
}

contract TimelockControllerInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ITimelockController private timelockController;
    TimelockControllerHandler private timelockControllerHandler;

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
        timelockController = ITimelockController(
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
    ITimelockController private timelockController;
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
