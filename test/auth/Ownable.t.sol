// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IOwnable} from "./interfaces/IOwnable.sol";

contract OwnableTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IOwnable private ownable;
    IOwnable private ownableInitialEvent;

    address private deployer = address(vyperDeployer);
    address private zeroAddress = address(0);

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
        emit OwnershipTransferred(zeroAddress, deployer);
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
        ownable.transfer_ownership(zeroAddress);
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = zeroAddress;
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
        vm.assume(newOwner1 != zeroAddress && newOwner2 != zeroAddress);
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
        vm.assume(newOwner != zeroAddress);
        address oldOwner = deployer;
        address renounceAddress = zeroAddress;
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

contract OwnableInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IOwnable private ownable;
    OwnerHandler private ownerHandler;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        ownable = IOwnable(
            vyperDeployer.deployContract("src/auth/", "Ownable")
        );
        ownerHandler = new OwnerHandler(ownable, deployer);
        targetContract(address(ownerHandler));
    }

    function invariantOwner() public {
        assertEq(ownable.owner(), ownerHandler.owner());
    }
}

contract OwnerHandler {
    address public owner;

    IOwnable private ownable;

    address private zeroAddress = address(0);

    constructor(IOwnable ownable_, address owner_) {
        ownable = ownable_;
        owner = owner_;
    }

    function transfer_ownership(address newOwner) public {
        ownable.transfer_ownership(newOwner);
        owner = newOwner;
    }

    function renounce_ownership() public {
        ownable.renounce_ownership();
        owner = zeroAddress;
    }
}
