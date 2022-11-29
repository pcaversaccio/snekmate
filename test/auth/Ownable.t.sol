// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IOwnable} from "./interfaces/IOwnable.sol";

contract OwnableTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IOwnable private ownable;

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
        assertTrue(ownable.owner() == address(vyperDeployer));
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
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ownable.transfer_ownership(vm.addr(1));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: new owner is the zero address"));
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
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ownable.renounce_ownership();
    }
}
