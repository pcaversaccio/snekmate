// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.31;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IPausable} from "./interfaces/IPausable.sol";

contract PausableTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IPausable private pausable;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        pausable = IPausable(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "pausable_mock"));
    }

    function testInitialSetup() public view {
        assertTrue(!pausable.paused());
    }

    function testPauseSuccess() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(deployer);
        pausable.pause();
        assertTrue(pausable.paused());
        vm.stopPrank();
    }

    function testPauseWhilePaused() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(deployer);
        pausable.pause();
        assertTrue(pausable.paused());

        vm.expectRevert(bytes("pausable: contract is paused"));
        pausable.pause();
        assertTrue(pausable.paused());
        vm.stopPrank();
    }

    function testUnpauseSuccess() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(deployer);
        pausable.pause();
        assertTrue(pausable.paused());
        vm.expectEmit(false, false, false, true);
        emit IPausable.Unpaused(deployer);
        pausable.unpause();
        assertTrue(!pausable.paused());
        vm.stopPrank();
    }

    function testUnpauseWhileUnpaused() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(deployer);
        pausable.pause();
        assertTrue(pausable.paused());
        vm.expectEmit(false, false, false, true);
        emit IPausable.Unpaused(deployer);
        pausable.unpause();
        assertTrue(!pausable.paused());

        vm.expectRevert(bytes("pausable: contract is not paused"));
        pausable.unpause();
        assertTrue(!pausable.paused());
        vm.stopPrank();
    }

    function testFuzzPauseSuccess(address account) public {
        vm.startPrank(account);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(account);
        pausable.pause();
        assertTrue(pausable.paused());
        vm.stopPrank();
    }

    function testFuzzPauseWhilePaused(address account) public {
        vm.startPrank(account);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(account);
        pausable.pause();
        assertTrue(pausable.paused());

        vm.expectRevert(bytes("pausable: contract is paused"));
        pausable.pause();
        assertTrue(pausable.paused());
        vm.stopPrank();
    }

    function testFuzzUnpauseSuccess(address account) public {
        vm.startPrank(account);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(account);
        pausable.pause();
        assertTrue(pausable.paused());
        vm.expectEmit(false, false, false, true);
        emit IPausable.Unpaused(account);
        pausable.unpause();
        assertTrue(!pausable.paused());
        vm.stopPrank();
    }

    function testFuzzUnpauseWhileUnpaused(address account) public {
        vm.startPrank(account);
        vm.expectEmit(false, false, false, true);
        emit IPausable.Paused(account);
        pausable.pause();
        assertTrue(pausable.paused());
        vm.expectEmit(false, false, false, true);
        emit IPausable.Unpaused(account);
        pausable.unpause();
        assertTrue(!pausable.paused());

        vm.expectRevert(bytes("pausable: contract is not paused"));
        pausable.unpause();
        assertTrue(!pausable.paused());
        vm.stopPrank();
    }
}

contract PausableInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IPausable private pausable;
    PausableHandler private pausableHandler;

    function setUp() public {
        pausable = IPausable(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "pausable_mock"));
        pausableHandler = new PausableHandler(pausable);
        targetContract(address(pausableHandler));
    }

    function statefulFuzzPaused() public view {
        assertEq(pausable.paused(), pausableHandler.paused());
    }
}

contract PausableHandler {
    bool public paused;

    IPausable private pausable;

    constructor(IPausable pausable_) {
        pausable = pausable_;
    }

    function pause() public {
        pausable.pause();
        paused = true;
    }

    function unpause() public {
        pausable.unpause();
        paused = false;
    }
}
