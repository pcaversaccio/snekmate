// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";

import {IERC2981Extended} from "./interfaces/IERC2981Extended.sol";

contract ERC2981Test is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    /* solhint-disable var-name-mixedcase */
    IERC2981Extended private ERC2981Extended;
    IERC2981Extended private ERC2981ExtendedInitialEvent;
    /* solhint-enable var-name-mixedcase */

    address private deployer = address(vyperDeployer);
    address private zeroAddress = address(0);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setUp() public {
        ERC2981Extended = IERC2981Extended(
            vyperDeployer.deployContract("src/extensions/", "ERC2981")
        );
    }

    function testInitialSetup() public {
        uint256 tokenId = 1;
        uint256 salePrice = 1_000;
        (address receiver, uint256 royaltyAmount) = ERC2981Extended.royaltyInfo(
            tokenId,
            salePrice
        );
        assertEq(ERC2981Extended.owner(), deployer);
        assertEq(receiver, zeroAddress);
        assertEq(royaltyAmount, 0);

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(zeroAddress, deployer);
        ERC2981ExtendedInitialEvent = IERC2981Extended(
            vyperDeployer.deployContract("src/extensions/", "ERC2981")
        );
        (
            address receiverInitialSetup,
            uint256 royaltyAmountInitialSetup
        ) = ERC2981ExtendedInitialEvent.royaltyInfo(tokenId, salePrice);
        assertEq(ERC2981ExtendedInitialEvent.owner(), deployer);
        assertEq(receiverInitialSetup, zeroAddress);
        assertEq(royaltyAmountInitialSetup, 0);
    }

    function testSupportsInterfaceSuccess() public {
        assertTrue(
            ERC2981Extended.supportsInterface(type(IERC165).interfaceId)
        );
        assertTrue(
            ERC2981Extended.supportsInterface(type(IERC2981).interfaceId)
        );
    }

    function testSupportsInterfaceGasCost() public {
        uint256 startGas = gasleft();
        ERC2981Extended.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(gasUsed <= 30_000);
    }

    function testSupportsInterfaceInvalidInterfaceId() public {
        assertTrue(!ERC2981Extended.supportsInterface(0x0011bbff));
    }

    function testRoyaltyInfoDefaultRoyalty() public {
        address owner = deployer;
        address receiver = makeAddr("receiver");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint96 royaltyFraction = 10;
        uint256 salePrice = 1_000;
        uint256 royalty = (salePrice * royaltyFraction) / 10_000;
        vm.startPrank(owner);
        ERC2981Extended.set_default_royalty(receiver, royaltyFraction);
        (address receiverAddr1, uint256 royaltyAmount1) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr2, uint256 royaltyAmount2) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertEq(receiverAddr1, receiverAddr2);
        assertEq(royaltyAmount1, royaltyAmount2);
        assertEq(receiver, receiverAddr1);
        assertEq(royalty, royaltyAmount1);
        assertEq(receiver, receiverAddr2);
        assertEq(royalty, royaltyAmount2);
        vm.stopPrank();
    }

    function testRoyaltyInfoUpdateDefaultRoyalty() public {
        address owner = deployer;
        address receiver1 = makeAddr("receiver1");
        address receiver2 = makeAddr("receiver2");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint96 royaltyFraction = 10;
        uint256 salePrice = 1_000;
        uint256 royalty1 = (salePrice * royaltyFraction) / 10_000;
        uint256 royalty2 = (salePrice * royaltyFraction * 2) / 10_000;
        vm.startPrank(owner);
        ERC2981Extended.set_default_royalty(receiver1, royaltyFraction);
        (address receiverAddr1, uint256 royaltyAmount1) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr2, uint256 royaltyAmount2) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertEq(receiverAddr1, receiverAddr2);
        assertEq(royaltyAmount1, royaltyAmount2);
        assertEq(receiver1, receiverAddr1);
        assertEq(receiver1, receiverAddr2);
        assertEq(royalty1, royaltyAmount1);
        assertEq(royalty1, royaltyAmount2);

        ERC2981Extended.set_default_royalty(receiver2, royaltyFraction * 2);
        (address receiverAddr3, uint256 royaltyAmount3) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr4, uint256 royaltyAmount4) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertEq(receiverAddr3, receiverAddr4);
        assertEq(royaltyAmount3, royaltyAmount4);
        assertEq(receiver2, receiverAddr3);
        assertEq(receiver2, receiverAddr4);
        assertEq(royalty2, royaltyAmount3);
        assertEq(royalty2, royaltyAmount4);
        vm.stopPrank();
    }

    function testRoyaltyInfoDeleteDefaultRoyalty() public {
        address owner = deployer;
        address receiver = makeAddr("receiver");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint96 royaltyFraction = 10;
        uint256 salePrice = 1_000;
        uint256 royalty = (salePrice * royaltyFraction) / 10_000;
        vm.startPrank(owner);
        ERC2981Extended.set_default_royalty(receiver, royaltyFraction);
        (address receiverAddr1, uint256 royaltyAmount1) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr2, uint256 royaltyAmount2) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertEq(receiverAddr1, receiverAddr2);
        assertEq(royaltyAmount1, royaltyAmount2);
        assertEq(receiver, receiverAddr1);
        assertEq(royalty, royaltyAmount1);
        assertEq(receiver, receiverAddr2);
        assertEq(royalty, royaltyAmount2);

        ERC2981Extended.delete_default_royalty();
        (address receiverAddr3, uint256 royaltyAmount3) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr4, uint256 royaltyAmount4) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertEq(receiverAddr3, receiverAddr4);
        assertEq(royaltyAmount3, royaltyAmount4);
        assertEq(receiverAddr3, zeroAddress);
        assertEq(royaltyAmount3, 0);
        assertEq(receiverAddr3, zeroAddress);
        assertEq(royaltyAmount4, 0);
        vm.stopPrank();
    }

    function testRoyaltyInfoSetTokenRoyalty() public {
        address owner = deployer;
        address receiver1 = makeAddr("receiver1");
        address receiver2 = makeAddr("receiver2");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint96 royaltyFraction = 10;
        uint256 salePrice = 1_000;
        uint256 royalty1 = (salePrice * royaltyFraction) / 10_000;
        uint256 royalty2 = (salePrice * royaltyFraction * 2) / 10_000;
        vm.startPrank(owner);
        ERC2981Extended.set_default_royalty(receiver1, royaltyFraction);
        ERC2981Extended.set_token_royalty(
            tokenId1,
            receiver2,
            royaltyFraction * 2
        );
        (address receiverAddr1, uint256 royaltyAmount1) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr2, uint256 royaltyAmount2) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertTrue(receiverAddr1 != receiverAddr2);
        assertTrue(royaltyAmount1 != royaltyAmount2);
        assertEq(receiver2, receiverAddr1);
        assertEq(royalty2, royaltyAmount1);
        assertEq(receiver1, receiverAddr2);
        assertEq(royalty1, royaltyAmount2);
        vm.stopPrank();
    }

    function testRoyaltyInfoSetTokenRoyaltyUpdate() public {
        address owner = deployer;
        address receiver1 = makeAddr("receiver1");
        address receiver2 = makeAddr("receiver2");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint96 royaltyFraction = 10;
        uint256 salePrice = 1_000;
        uint256 royalty1 = (salePrice * royaltyFraction) / 10_000;
        uint256 royalty2 = (salePrice * royaltyFraction * 2) / 10_000;
        vm.startPrank(owner);
        ERC2981Extended.set_default_royalty(receiver1, royaltyFraction);
        ERC2981Extended.set_token_royalty(
            tokenId1,
            receiver2,
            royaltyFraction * 2
        );
        (address receiverAddr1, uint256 royaltyAmount1) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr2, uint256 royaltyAmount2) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertTrue(receiverAddr1 != receiverAddr2);
        assertTrue(royaltyAmount1 != royaltyAmount2);
        assertEq(receiver2, receiverAddr1);
        assertEq(royalty2, royaltyAmount1);
        assertEq(receiver1, receiverAddr2);
        assertEq(royalty1, royaltyAmount2);

        ERC2981Extended.set_token_royalty(
            tokenId2,
            receiver2,
            royaltyFraction * 2
        );
        (address receiverAddr3, uint256 royaltyAmount3) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr4, uint256 royaltyAmount4) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertEq(receiverAddr3, receiverAddr4);
        assertEq(royaltyAmount3, royaltyAmount4);
        assertEq(receiver2, receiverAddr3);
        assertEq(royalty2, royaltyAmount3);
        assertEq(receiver2, receiverAddr4);
        assertEq(royalty2, royaltyAmount4);
        vm.stopPrank();
    }

    function testResetTokenRoyalty() public {
        address owner = deployer;
        address receiver1 = makeAddr("receiver1");
        address receiver2 = makeAddr("receiver2");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint96 royaltyFraction = 10;
        uint256 salePrice = 1_000;
        uint256 royalty1 = (salePrice * royaltyFraction) / 10_000;
        uint256 royalty2 = (salePrice * royaltyFraction * 2) / 10_000;
        vm.startPrank(owner);
        ERC2981Extended.set_default_royalty(receiver1, royaltyFraction);
        ERC2981Extended.set_token_royalty(
            tokenId1,
            receiver2,
            royaltyFraction * 2
        );
        (address receiverAddr1, uint256 royaltyAmount1) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        (address receiverAddr2, uint256 royaltyAmount2) = ERC2981Extended
            .royaltyInfo(tokenId2, salePrice);
        assertTrue(receiverAddr1 != receiverAddr2);
        assertTrue(royaltyAmount1 != royaltyAmount2);
        assertEq(receiver2, receiverAddr1);
        assertEq(royalty2, royaltyAmount1);
        assertEq(receiver1, receiverAddr2);
        assertEq(royalty1, royaltyAmount2);

        ERC2981Extended.reset_token_royalty(tokenId1);
        (address receiverAddr3, uint256 royaltyAmount3) = ERC2981Extended
            .royaltyInfo(tokenId1, salePrice);
        assertEq(receiverAddr3, receiverAddr2);
        assertEq(royaltyAmount3, royaltyAmount2);
        assertEq(receiver1, receiverAddr2);
        assertEq(royalty1, royaltyAmount2);
        assertEq(receiver1, receiverAddr3);
        assertEq(royalty1, royaltyAmount3);
        vm.stopPrank();
    }

    function testRoyaltyInfoOverflow() public {
        address owner = deployer;
        vm.startPrank(owner);
        ERC2981Extended.set_default_royalty(makeAddr("receiver"), 10);
        vm.expectRevert();
        ERC2981Extended.royaltyInfo(1, type(uint256).max);
        vm.stopPrank();
    }

    function testSetDefaultRoyaltyTooHighFeeNumerator() public {
        address owner = deployer;
        vm.startPrank(owner);
        vm.expectRevert("ERC2981: royalty fee will exceed sale_price");
        ERC2981Extended.set_default_royalty(makeAddr("receiver"), 11_000);
        vm.stopPrank();
    }

    function testSetDefaultRoyaltyInvalidReceiver() public {
        address owner = deployer;
        vm.startPrank(owner);
        vm.expectRevert("ERC2981: invalid receiver");
        ERC2981Extended.set_default_royalty(zeroAddress, 10);
        vm.stopPrank();
    }

    function testSetDefaultRoyaltyNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        ERC2981Extended.set_default_royalty(zeroAddress, 10);
    }

    function testDeleteDefaultRoyaltyNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        ERC2981Extended.delete_default_royalty();
    }

    function testSetTokenRoyaltyTooHighFeeNumerator() public {
        address owner = deployer;
        vm.startPrank(owner);
        vm.expectRevert("ERC2981: royalty fee will exceed sale_price");
        ERC2981Extended.set_token_royalty(1, makeAddr("receiver"), 11_000);
        vm.stopPrank();
    }

    function testSetTokenRoyaltyInvalidReceiver() public {
        address owner = deployer;
        vm.startPrank(owner);
        vm.expectRevert("ERC2981: invalid receiver");
        ERC2981Extended.set_token_royalty(1, zeroAddress, 10);
        vm.stopPrank();
    }

    function testSetTokenRoyaltyNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        ERC2981Extended.set_token_royalty(1, zeroAddress, 10);
    }

    function testResetTokenRoyaltyNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        ERC2981Extended.reset_token_royalty(1);
    }

    function testHasOwner() public {
        assertEq(ERC2981Extended.owner(), deployer);
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC2981Extended.transfer_ownership(newOwner);
        assertEq(ERC2981Extended.owner(), newOwner);
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC2981Extended.transfer_ownership(makeAddr("newOwner"));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("Ownable: new owner is the zero address"));
        ERC2981Extended.transfer_ownership(zeroAddress);
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = zeroAddress;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC2981Extended.renounce_ownership();
        assertEq(ERC2981Extended.owner(), newOwner);
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC2981Extended.renounce_ownership();
    }
}
