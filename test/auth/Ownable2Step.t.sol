// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IOwnable2Step} from "./interfaces/IOwnable2Step.sol";

contract Ownable2StepTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IOwnable2Step private ownable2Step;
    IOwnable2Step private ownable2StepInitialEvent;

    address private deployer = address(vyperDeployer);
    address private zeroAddress = address(0);

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
        assertEq(ownable2Step.pending_owner(), zeroAddress);
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
        assertEq(ownable2Step.pending_owner(), zeroAddress);
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
        address newOwner = zeroAddress;
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

    function testFuzzTransferOwnershipSuccess(
        address newOwner1,
        address newOwner2
    ) public {
        vm.assume(newOwner1 != zeroAddress && newOwner2 != zeroAddress);
        address oldOwner = deployer;
        vm.startPrank(oldOwner);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner1);
        ownable2Step.transfer_ownership(newOwner1);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner1);

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner2);
        ownable2Step.transfer_ownership(newOwner2);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner2);
        vm.stopPrank();
    }

    function testFuzzTransferOwnershipNonOwner(
        address nonOwner,
        address newOwner
    ) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable2Step: caller is not the owner"));
        ownable2Step.transfer_ownership(newOwner);
    }

    function testFuzzAcceptOwnershipSuccess(
        address newOwner1,
        address newOwner2
    ) public {
        vm.assume(newOwner1 != zeroAddress && newOwner2 != zeroAddress);
        address oldOwner = deployer;
        vm.startPrank(oldOwner);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner1);
        ownable2Step.transfer_ownership(newOwner1);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner1);
        vm.stopPrank();

        vm.startPrank(newOwner1);
        emit OwnershipTransferred(oldOwner, newOwner1);
        ownable2Step.accept_ownership();
        assertEq(ownable2Step.owner(), newOwner1);
        assertEq(ownable2Step.pending_owner(), zeroAddress);

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(newOwner1, newOwner2);
        ownable2Step.transfer_ownership(newOwner2);
        assertEq(ownable2Step.owner(), newOwner1);
        assertEq(ownable2Step.pending_owner(), newOwner2);
        vm.stopPrank();

        vm.startPrank(newOwner2);
        emit OwnershipTransferred(newOwner1, newOwner2);
        ownable2Step.accept_ownership();
        assertEq(ownable2Step.owner(), newOwner2);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.stopPrank();
    }

    function testFuzzAcceptOwnershipNonPendingOwner(address newOwner) public {
        vm.assume(newOwner != zeroAddress && newOwner != deployer);
        address oldOwner = deployer;
        vm.startPrank(oldOwner);
        assertEq(ownable2Step.pending_owner(), zeroAddress);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(oldOwner, newOwner);
        ownable2Step.transfer_ownership(newOwner);
        assertEq(ownable2Step.owner(), oldOwner);
        assertEq(ownable2Step.pending_owner(), newOwner);

        vm.expectRevert(bytes("Ownable2Step: caller is not the new owner"));
        ownable2Step.accept_ownership();
        vm.stopPrank();
    }

    function testFuzzRenounceOwnershipSuccess(address newOwner) public {
        vm.assume(newOwner != zeroAddress);
        address oldOwner = deployer;
        address renounceAddress = zeroAddress;
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

        vm.startPrank(newOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(newOwner, renounceAddress);
        ownable2Step.renounce_ownership();
        assertEq(ownable2Step.owner(), renounceAddress);
        vm.stopPrank();
    }

    function testFuzzRenounceOwnershipNonOwner(address nonOwner) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable2Step: caller is not the owner"));
        ownable2Step.renounce_ownership();
    }

    function testFuzzPendingOwnerResetAfterRenounceOwnership(
        address newOwner
    ) public {
        vm.assume(newOwner != zeroAddress);
        address oldOwner = deployer;
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

contract Ownable2StepInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IOwnable2Step private ownable2Step;
    Owner2StepHandler private owner2StepHandler;

    address private deployer = address(vyperDeployer);
    address private zeroAddress = address(0);

    function setUp() public {
        ownable2Step = IOwnable2Step(
            vyperDeployer.deployContract("src/auth/", "Ownable2Step")
        );
        owner2StepHandler = new Owner2StepHandler(
            ownable2Step,
            deployer,
            zeroAddress
        );
        targetContract(address(owner2StepHandler));
    }

    function invariantOwner() public {
        assertEq(ownable2Step.owner(), owner2StepHandler.owner());
    }

    function invariantPendingOwner() public {
        assertEq(
            ownable2Step.pending_owner(),
            owner2StepHandler.pending_owner()
        );
    }
}

contract Owner2StepHandler {
    address public owner;
    // solhint-disable-next-line var-name-mixedcase
    address public pending_owner;

    IOwnable2Step private ownable2Step;

    address private zeroAddress = address(0);

    constructor(
        IOwnable2Step ownable2Step_,
        address owner_,
        // solhint-disable-next-line var-name-mixedcase
        address pending_owner_
    ) {
        ownable2Step = ownable2Step_;
        owner = owner_;
        pending_owner = pending_owner_;
    }

    function transfer_ownership(address newOwner) public {
        ownable2Step.transfer_ownership(newOwner);
        pending_owner = newOwner;
    }

    function accept_ownership() public {
        ownable2Step.accept_ownership();
        owner = address(this);
        pending_owner = zeroAddress;
    }

    function renounce_ownership() public {
        ownable2Step.renounce_ownership();
        owner = zeroAddress;
        pending_owner = zeroAddress;
    }
}
