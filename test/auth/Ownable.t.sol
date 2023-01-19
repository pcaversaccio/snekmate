// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IOwnable} from "./interfaces/IOwnable.sol";

contract OwnableTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

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
        address deployer = address(vyperDeployer);
        assertEq(ownable.owner(), deployer);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(0), deployer);
        ownableInitialEvent = IOwnable(
            vyperDeployer.deployContract("src/auth/", "Ownable")
        );
        assertEq(ownableInitialEvent.owner(), deployer);
    }

    function testHasOwner() public {
        assertEq(ownable.owner(), address(vyperDeployer));
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ownable.transfer_ownership(newOwner);
        assertEq(ownable.owner(), newOwner);
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownable.transfer_ownership(vm.addr(1));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("Ownable: new owner is the zero address"));
        ownable.transfer_ownership(address(0));
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
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
        address oldOwner = address(vyperDeployer);
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
        vm.assume(nonOwner != address(vyperDeployer));
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownable.transfer_ownership(newOwner);
    }

    function testFuzzRenounceOwnershipSuccess(address newOwner) public {
        address oldOwner = address(vyperDeployer);
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
        vm.assume(nonOwner != address(vyperDeployer));
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownable.renounce_ownership();
    }
}
