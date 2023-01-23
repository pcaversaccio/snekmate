// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {InvariantTest} from "forge-std/InvariantTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IOwnable2Step} from "./interfaces/IOwnable2Step.sol";

contract Ownable2StepTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    address private deployer = address(vyperDeployer);

    IOwnable2Step private ownable2Step;
    IOwnable2Step private ownable2StepInitialEvent;

    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setUp() public {
        ownable2Step = IOwnable2Step(
            vyperDeployer.deployContract("src/auth/", "Ownable2Step")
        );
    }

    function testInitialSetup() public {
        address zeroAddress = address(0);
        assertEq(ownable2Step.owner(), deployer);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(zeroAddress, deployer);
        ownable2StepInitialEvent = IOwnable2Step(
            vyperDeployer.deployContract("src/auth/", "Ownable2Step")
        );
        assertEq(ownable2StepInitialEvent.owner(), deployer);
        assertEq(ownable2StepInitialEvent.pending_owner(), zeroAddress);
    }

    function testHasOwner() public {
        assertEq(ownable2Step.owner(), deployer);
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        vm.startPrank(oldOwner);
        assertEq(ownable2Step.pending_owner(), address(0));
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner);
        ownable2Step.transfer_ownership(newOwner);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner);
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable2Step: caller is not the owner"));
        ownable2Step.transfer_ownership(makeAddr("newOwner"));
    }

    function testAcceptOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        address zeroAddress = address(0);
        vm.startPrank(oldOwner);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner);
        ownable2Step.transfer_ownership(newOwner);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner);
        vm.stopPrank();

        vm.startPrank(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
        ownable2Step.accept_ownership();
        assertEq(ownable2Step.owner(), newOwner);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.stopPrank();
    }

    function testAcceptOwnershipNonPendingOwner() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        vm.startPrank(oldOwner);
        assertEq(ownable2Step.pending_owner(), address(0));
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner);
        ownable2Step.transfer_ownership(newOwner);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner);
        vm.expectRevert(bytes("Ownable2Step: caller is not the new owner"));
        ownable2Step.accept_ownership();
        vm.stopPrank();
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = address(0);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ownable2Step.renounce_ownership();
        assertEq(ownable2Step.owner(), newOwner);
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable2Step: caller is not the owner"));
        ownable2Step.renounce_ownership();
    }

    function testPendingOwnerResetAfterRenounceOwnership() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        address zeroAddress = address(0);
        vm.startPrank(oldOwner);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner);
        ownable2Step.transfer_ownership(newOwner);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner);
        ownable2Step.renounce_ownership();
        assertEq(ownable2Step.owner(), zeroAddress);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.stopPrank();

        vm.startPrank(newOwner);
        vm.expectRevert(bytes("Ownable2Step: caller is not the new owner"));
        ownable2Step.accept_ownership();
        vm.stopPrank();
    }
}
