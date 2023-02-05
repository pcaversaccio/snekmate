// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IOwnable2Step} from "./interfaces/IOwnable2Step.sol";

contract Ownable2StepTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IOwnable2Step private ownable2Step;

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
        assertTrue(ownable2Step.owner() == address(vyperDeployer));
        assertTrue(ownable2Step.pending_owner() == address(0));
    }

    function testHasOwner() public {
        assertEq(ownable2Step.owner(), address(vyperDeployer));
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
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
        ownable2Step.transfer_ownership(vm.addr(1));
    }

    function testAcceptOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
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
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
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
        address oldOwner = address(vyperDeployer);
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
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
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
        vm.expectRevert(bytes("Ownable2Step: caller is not the new owner"));
        ownable2Step.accept_ownership();
        vm.stopPrank();
    }
}
