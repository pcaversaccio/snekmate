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
        timelockController =
            TimelockController(payable(vyperDeployer.deployContract("src/governance/", "TimelockController", args)));

        counter = new Counter(address(timelockController));

        calls.push(Call({target: address(counter), value: 0, data: abi.encodeWithSelector(Counter.increment.selector)}));
        calls.push(
            Call({target: address(counter), value: 0, data: abi.encodeWithSelector(Counter.setNumber.selector, 10)})
        );
    }

    function checkRoleNotSetForAddresses(TimelockController timelock, bytes32 role, address[2] storage addresses)
        internal
    {
        for (uint256 i = 0; i < addresses.length; ++i) {
            assertFalse(timelock.hasRole(role, addresses[i]));
        }
    }

    function testInitialSetup() public {
        assertEq(timelockController.hasRole(timelockController.DEFAULT_ADMIN_ROLE(), address(this)), true);

        checkRoleNotSetForAddresses(timelockController, timelockController.DEFAULT_ADMIN_ROLE(), PROPOSERS);
        checkRoleNotSetForAddresses(timelockController, timelockController.DEFAULT_ADMIN_ROLE(), EXECUTORS);

        assertEq(timelockController.hasRole(timelockController.PROPOSER_ROLE(), PROPOSER_ONE), true);
        assertEq(timelockController.hasRole(timelockController.PROPOSER_ROLE(), PROPOSER_TWO), true);

        assertFalse(timelockController.hasRole(timelockController.PROPOSER_ROLE(), ADMIN));

        checkRoleNotSetForAddresses(timelockController, timelockController.PROPOSER_ROLE(), EXECUTORS);

        assertEq(timelockController.hasRole(timelockController.EXECUTOR_ROLE(), EXECUTOR_ONE), true);
        assertEq(timelockController.hasRole(timelockController.EXECUTOR_ROLE(), EXECUTOR_TWO), true);
        assertFalse(timelockController.hasRole(timelockController.EXECUTOR_ROLE(), ADMIN));
        checkRoleNotSetForAddresses(timelockController, timelockController.EXECUTOR_ROLE(), PROPOSERS);
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
        payloads[0] = abi.encodeWithSelector(this.testHashesBatchedOperationsCorrectly.selector);
        payloads[1] = abi.encodeWithSelector(this.testHashesBatchedOperationsCorrectly.selector);

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        bytes32 hashedOperation = timelockController.hashOperationBatch(targets, values, payloads, predecessor, salt);
        bytes32 expectedHash = keccak256(abi.encode(targets, values, payloads, predecessor, salt));
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
        bytes memory data = abi.encodeWithSelector(timelockController.updateDelay.selector, MIN_DELAY);

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        vm.prank(PROPOSER_ONE);
        timelockController.schedule(target, value, data, predecessor, salt, MIN_DELAY);

        vm.warp(block.timestamp + MIN_DELAY);

        vm.prank(EXECUTOR_ONE);
        timelockController.execute(target, value, data, predecessor, salt);

        uint256 minDelay = timelockController.getMinDelay();
        assertEq(minDelay, 3 days);
    }

    function testRevertWhenLessThanMinDelay() public {
        address target = address(timelockController);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(timelockController.updateDelay.selector, 0);

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        vm.expectRevert("TimelockController: insufficient delay");
        vm.prank(PROPOSER_ONE);
        timelockController.schedule(target, value, data, predecessor, salt, MIN_DELAY - 1);
    }

    function testUpdatesDelayAtLeastMinDelay() public {
        vm.prank(address(timelockController));
        timelockController.updateDelay(0); // set min delay to 0

        address target = address(timelockController);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(timelockController.updateDelay.selector, MIN_DELAY);

        bytes32 predecessor = NO_PREDECESSOR;
        bytes32 salt = EMPTY_SALT;

        vm.prank(PROPOSER_ONE);
        timelockController.schedule(target, value, data, NO_PREDECESSOR, EMPTY_SALT, 1);

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
        timelockController.scheduleBatch(targets, values, payloads, NO_PREDECESSOR, EMPTY_SALT, MIN_DELAY);
    }

    function _scheduleBatchedOperation(address proposer) internal {
        address[] memory targets = new address[](calls.length);
        uint256[] memory values = new uint256[](calls.length);
        bytes[] memory payloads = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; ++i) {
            targets[i] = calls[i].target;
            values[i] = calls[i].value;
            payloads[i] = calls[i].data;
        }

        bytes32 batchedOperationID =
            timelockController.hashOperationBatch(targets, values, payloads, NO_PREDECESSOR, EMPTY_SALT);
        assertEq(timelockController.isOperation(batchedOperationID), false);

        vm.prank(proposer);
        timelockController.scheduleBatch(targets, values, payloads, NO_PREDECESSOR, EMPTY_SALT, MIN_DELAY);

        assertEq(timelockController.isOperation(batchedOperationID), true);
    }

    function testProposerCanBatchSchedule() public {
        _scheduleBatchedOperation(PROPOSER_ONE);
    }

    function testAdminCanBatchSchedule() public {
        _scheduleBatchedOperation(ADMIN);
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
