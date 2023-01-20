// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IOwnable} from "./interfaces/IOwnable.sol";

contract OwnableTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    address private deployer = address(vyperDeployer);

    IOwnable private ownable;
    IOwnable private ownableInitialEvent;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setUp() public {
        ownable = IOwnable(
            vyperDeployer.deployContract("src/auth/", "Ownable")
        );
    }

    function testInitialSetup() public {
        assertEq(ownable.owner(), deployer);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(0), deployer);
        ownableInitialEvent = IOwnable(
            vyperDeployer.deployContract("src/auth/", "Ownable")
        );
        assertEq(ownableInitialEvent.owner(), deployer);
    }

    function testHasOwner() public {
        assertEq(ownable.owner(), deployer);
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ownable.transfer_ownership(newOwner);
        assertEq(ownable.owner(), newOwner);
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownable.transfer_ownership(makeAddr("newOwner"));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("Ownable: new owner is the zero address"));
        ownable.transfer_ownership(address(0));
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = address(0);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ownable.renounce_ownership();
        assertEq(ownable.owner(), newOwner);
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownable.renounce_ownership();
    }

    function testFuzzTransferOwnershipSuccess(
        address newOwner1,
        address newOwner2
    ) public {
        vm.assume(newOwner1 != address(0) && newOwner2 != address(0));
        address oldOwner = deployer;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner1);
        ownable.transfer_ownership(newOwner1);
        assertEq(ownable.owner(), newOwner1);
        vm.stopPrank();

        vm.startPrank(newOwner1);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(newOwner1, newOwner2);
        ownable.transfer_ownership(newOwner2);
        assertEq(ownable.owner(), newOwner2);
        vm.stopPrank();
    }

    function testFuzzTransferOwnershipNonOwner(
        address nonOwner,
        address newOwner
    ) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownable.transfer_ownership(newOwner);
    }

    function testFuzzRenounceOwnershipSuccess(address newOwner) public {
        vm.assume(newOwner != address(0));
        address oldOwner = deployer;
        address renounceAddress = address(0);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ownable.transfer_ownership(newOwner);
        assertEq(ownable.owner(), newOwner);
        vm.stopPrank();

        vm.startPrank(newOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(newOwner, renounceAddress);
        ownable.renounce_ownership();
        assertEq(ownable.owner(), renounceAddress);
        vm.stopPrank();
    }

    function testFuzzRenounceOwnershipNonOwner(address nonOwner) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownable.renounce_ownership();
    }
}
