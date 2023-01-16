// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "openzeppelin/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC1155ReceiverMock} from "./mocks/ERC1155ReceiverMock.sol";

import {IERC1155Extended} from "./interfaces/IERC1155Extended.sol";

contract ERC1155Test is Test {
    string private constant _BASE_URI = "https://www.wagmi.xyz/";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC1155Extended private ERC1155Extended;
    // solhint-disable-next-line var-name-mixedcase
    IERC1155Extended private ERC1155ExtendedNoBaseURI;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    event Received(
        address indexed operator,
        address indexed from,
        uint256 id,
        uint256 amount,
        bytes data
    );

    event BatchReceived(
        address indexed operator,
        address indexed from,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event RoleMinterChanged(address indexed minter, bool status);

    function setUp() public {
        bytes memory args = abi.encode(_BASE_URI);
        ERC1155Extended = IERC1155Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC1155", args)
        );
    }

    function testInitialSetup() public {
        address deployer = address(vyperDeployer);
        assertTrue(ERC1155Extended.owner() == deployer);
        assertTrue(ERC1155Extended.is_minter(deployer));
        assertEq(
            ERC1155Extended.uri(0),
            string.concat(_BASE_URI, Strings.toString(uint256(0)))
        );
        assertEq(
            ERC1155Extended.uri(1),
            string.concat(_BASE_URI, Strings.toString(uint256(1)))
        );
    }

    function testSupportsInterfaceSuccess() public {
        assertTrue(
            ERC1155Extended.supportsInterface(type(IERC165).interfaceId)
        );
        assertTrue(
            ERC1155Extended.supportsInterface(type(IERC1155).interfaceId)
        );
        assertTrue(
            ERC1155Extended.supportsInterface(
                type(IERC1155MetadataURI).interfaceId
            )
        );
    }

    function testSupportsInterfaceGasCost() public {
        uint256 startGas = gasleft();
        ERC1155Extended.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(gasUsed < 30_000);
    }

    function testSupportsInterfaceInvalidInterfaceId() public {
        assertTrue(!ERC1155Extended.supportsInterface(0x0011bbff));
    }

    function testBalanceOfCase1() public {
        address deployer = address(vyperDeployer);
        address firstOwner = vm.addr(1);
        address secondOwner = vm.addr(2);
        uint256 id1 = 0;
        uint256 amountFirstOwner = 1;
        uint256 id2 = 1;
        uint256 amountSecondOwner = 20;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(firstOwner, id1, amountFirstOwner, data);
        ERC1155Extended.safe_mint(secondOwner, id2, amountSecondOwner, data);
        assertEq(ERC1155Extended.balanceOf(firstOwner, id1), amountFirstOwner);
        assertEq(
            ERC1155Extended.balanceOf(secondOwner, id2),
            amountSecondOwner
        );
        assertEq(ERC1155Extended.balanceOf(firstOwner, 2), 0);
        vm.stopPrank();
    }

    function testBalanceOfCase2() public {
        assertEq(ERC1155Extended.balanceOf(vm.addr(1), 0), 0);
        assertEq(ERC1155Extended.balanceOf(vm.addr(2), 1), 0);
        assertEq(ERC1155Extended.balanceOf(vm.addr(3), 2), 0);
    }

    function testBalanceOfZeroAddress() public {
        vm.expectRevert(bytes("ERC1155: address zero is not a valid owner"));
        ERC1155Extended.balanceOf(address(0), 0);
    }

    function testBalanceOfBatchCase1() public {
        address deployer = address(vyperDeployer);
        address firstOwner = vm.addr(1);
        address secondOwner = vm.addr(2);
        address[] memory owners = new address[](6);
        uint256[] memory ids = new uint256[](6);
        uint256[] memory amounts = new uint256[](6);
        bytes memory data = new bytes(0);

        owners[0] = firstOwner;
        owners[1] = firstOwner;
        owners[2] = secondOwner;
        owners[3] = secondOwner;
        owners[4] = firstOwner;
        owners[5] = secondOwner;
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        ids[4] = 4;
        ids[5] = 5;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;
        amounts[4] = 0;
        amounts[5] = 0;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owners[0], ids[0], amounts[0], data);
        ERC1155Extended.safe_mint(owners[1], ids[1], amounts[1], data);
        ERC1155Extended.safe_mint(owners[2], ids[2], amounts[2], data);
        ERC1155Extended.safe_mint(owners[3], ids[3], amounts[3], data);
        uint256[] memory balances = ERC1155Extended.balanceOfBatch(owners, ids);
        assertEq(balances.length, 6);
        for (uint256 i; i < balances.length; ++i) {
            assertEq(balances[i], amounts[i]);
        }
        vm.stopPrank();
    }

    function testBalanceOfBatchCase2() public {
        address deployer = address(vyperDeployer);
        address firstOwner = vm.addr(1);
        address secondOwner = vm.addr(2);
        address[] memory owners = new address[](6);
        uint256[] memory ids = new uint256[](6);
        uint256[] memory amounts = new uint256[](6);
        bytes memory data = new bytes(0);

        owners[0] = firstOwner;
        owners[1] = firstOwner;
        owners[2] = owners[0];
        owners[3] = secondOwner;
        owners[4] = firstOwner;
        owners[5] = owners[3];
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = ids[0];
        ids[3] = 3;
        ids[4] = 4;
        ids[5] = ids[3];
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = amounts[0];
        amounts[3] = 20;
        amounts[4] = 0;
        amounts[5] = amounts[3];

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owners[0], ids[0], amounts[0] - 1, data);
        ERC1155Extended.safe_mint(owners[1], ids[1], amounts[1], data);
        ERC1155Extended.safe_mint(owners[2], ids[2], amounts[2], data);
        ERC1155Extended.safe_mint(owners[3], ids[3], amounts[3], data);
        uint256[] memory balances = ERC1155Extended.balanceOfBatch(owners, ids);
        assertEq(balances.length, 6);
        for (uint256 i; i < balances.length; ++i) {
            assertEq(balances[i], amounts[i]);
        }
        vm.stopPrank();
    }

    function testBalanceOfBatchCase3() public {
        address firstOwner = vm.addr(1);
        address secondOwner = vm.addr(2);
        address[] memory owners = new address[](6);
        uint256[] memory ids = new uint256[](6);

        owners[0] = firstOwner;
        owners[1] = firstOwner;
        owners[2] = secondOwner;
        owners[3] = secondOwner;
        owners[4] = firstOwner;
        owners[5] = secondOwner;
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        ids[4] = 4;
        ids[5] = 5;

        uint256[] memory balances = ERC1155Extended.balanceOfBatch(owners, ids);
        assertEq(balances.length, 6);
        for (uint256 i; i < balances.length; ++i) {
            assertEq(balances[i], 0);
        }
    }

    function testBalanceOfBatchLengthsMismatch() public {
        address[] memory owners1 = new address[](2);
        uint256[] memory ids1 = new uint256[](1);
        owners1[0] = vm.addr(1);
        owners1[1] = vm.addr(2);
        ids1[0] = 0;
        vm.expectRevert(bytes("ERC1155: owners and ids length mismatch"));
        ERC1155Extended.balanceOfBatch(owners1, ids1);

        address[] memory owners2 = new address[](1);
        uint256[] memory ids2 = new uint256[](2);
        owners2[0] = vm.addr(3);
        ids2[0] = 0;
        ids2[1] = 1;
        vm.expectRevert(bytes("ERC1155: owners and ids length mismatch"));
        ERC1155Extended.balanceOfBatch(owners2, ids2);
    }

    function testBalanceOfBatchZeroAddress() public {
        address[] memory owners = new address[](1);
        uint256[] memory ids = new uint256[](1);
        owners[0] = address(0);
        ids[0] = 0;
        vm.expectRevert(bytes("ERC1155: address zero is not a valid owner"));
        ERC1155Extended.balanceOfBatch(owners, ids);
    }

    function testSetApprovalForAllSuccess() public {
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        bool approved = true;
        assertTrue(!ERC1155Extended.isApprovedForAll(owner, operator));
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC1155Extended.isApprovedForAll(owner, operator));

        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC1155Extended.isApprovedForAll(owner, operator));
        vm.stopPrank();
    }

    function testSetApprovalForAllRevoke() public {
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        bool approved = true;
        assertTrue(!ERC1155Extended.isApprovedForAll(owner, operator));
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC1155Extended.isApprovedForAll(owner, operator));

        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, !approved);
        ERC1155Extended.setApprovalForAll(operator, !approved);
        assertTrue(!ERC1155Extended.isApprovedForAll(owner, operator));
        vm.stopPrank();
    }

    function testSetApprovalForAllToSelf() public {
        address owner = vm.addr(1);
        vm.expectRevert(bytes("ERC1155: setting approval status for self"));
        vm.prank(owner);
        ERC1155Extended.setApprovalForAll(owner, true);
    }

    function testSafeTransferFromEOAReceiver() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(owner, owner, receiver, id1, amount1);
        ERC1155Extended.safeTransferFrom(owner, receiver, id1, amount1, data);
        assertEq(ERC1155Extended.balanceOf(owner, id1), 0);
        assertEq(ERC1155Extended.balanceOf(owner, id2), amount2);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), 0);
        vm.stopPrank();
    }

    function testSafeTransferFromByApprovedOperator() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        address operator = vm.addr(3);
        bool approved = true;
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(operator, owner, receiver, id1, amount1);
        ERC1155Extended.safeTransferFrom(owner, receiver, id1, amount1, data);
        assertEq(ERC1155Extended.balanceOf(owner, id1), 0);
        assertEq(ERC1155Extended.balanceOf(owner, id2), amount2);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), 0);
        assertEq(ERC1155Extended.balanceOf(operator, id1), 0);
        assertEq(ERC1155Extended.balanceOf(operator, id2), 0);
        vm.stopPrank();
    }

    function testSafeTransferFromByNotApprovedOperator() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        address operator = vm.addr(3);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(operator);
        vm.expectRevert(
            bytes("ERC1155: caller is not token owner or approved")
        );
        ERC1155Extended.safeTransferFrom(owner, receiver, id1, amount1, data);
        vm.stopPrank();
    }

    function testSafeTransferFromNoData() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(owner, owner, receiver, id1, amount1);
        vm.expectEmit(true, true, false, true, receiver);
        emit Received(owner, owner, id1, amount1, data);
        ERC1155Extended.safeTransferFrom(owner, receiver, id1, amount1, data);
        assertEq(ERC1155Extended.balanceOf(owner, id1), 0);
        assertEq(ERC1155Extended.balanceOf(owner, id2), amount2);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), 0);
        vm.stopPrank();

        address operator = vm.addr(3);
        bool approved = true;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(operator, owner, receiver, id2, amount2);
        vm.expectEmit(true, true, false, true, receiver);
        emit Received(operator, owner, id2, amount2, data);
        ERC1155Extended.safeTransferFrom(owner, receiver, id2, amount2, data);
        assertEq(ERC1155Extended.balanceOf(owner, id1), 0);
        assertEq(ERC1155Extended.balanceOf(owner, id2), 0);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), amount2);
        assertEq(ERC1155Extended.balanceOf(operator, id1), 0);
        assertEq(ERC1155Extended.balanceOf(operator, id2), 0);
        vm.stopPrank();
    }

    function testSafeTransferFromWithData() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(42);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(owner, owner, receiver, id1, amount1);
        vm.expectEmit(true, true, false, true, receiver);
        emit Received(owner, owner, id1, amount1, data);
        ERC1155Extended.safeTransferFrom(owner, receiver, id1, amount1, data);
        assertEq(ERC1155Extended.balanceOf(owner, id1), 0);
        assertEq(ERC1155Extended.balanceOf(owner, id2), amount2);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), 0);
        vm.stopPrank();

        address operator = vm.addr(3);
        bool approved = true;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(operator, owner, receiver, id2, amount2);
        vm.expectEmit(true, true, false, true, receiver);
        emit Received(operator, owner, id2, amount2, data);
        ERC1155Extended.safeTransferFrom(owner, receiver, id2, amount2, data);
        assertEq(ERC1155Extended.balanceOf(owner, id1), 0);
        assertEq(ERC1155Extended.balanceOf(owner, id2), 0);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), amount2);
        assertEq(ERC1155Extended.balanceOf(operator, id1), 0);
        assertEq(ERC1155Extended.balanceOf(operator, id2), 0);
        vm.stopPrank();
    }

    function testSafeTransferFromReceiverInvalidReturnIdentifier() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = 0x00bb8833;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );
        ERC1155Extended.safeTransferFrom(owner, receiver, id1, amount1, data);
        vm.stopPrank();

        address operator = vm.addr(3);
        bool approved = true;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );
        ERC1155Extended.safeTransferFrom(owner, receiver, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeTransferFromReceiverReverts() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            true,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC1155ReceiverMock: reverting on receive"));
        ERC1155Extended.safeTransferFrom(owner, receiver, id1, amount1, data);
        vm.stopPrank();

        address operator = vm.addr(3);
        bool approved = true;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectRevert(bytes("ERC1155ReceiverMock: reverting on receive"));
        ERC1155Extended.safeTransferFrom(owner, receiver, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeTransferFromReceiverFunctionNotImplemented() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert();
        ERC1155Extended.safeTransferFrom(owner, deployer, id1, amount1, data);
        vm.stopPrank();

        address operator = vm.addr(3);
        bool approved = true;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectRevert();
        ERC1155Extended.safeTransferFrom(owner, deployer, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeTransferFromInsufficientBalance() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 id = 2;
        uint256 amount = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id, amount, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));
        ERC1155Extended.safeTransferFrom(owner, vm.addr(2), id, ++amount, data);
        vm.stopPrank();
    }

    function testSafeTransferFromToZeroAddress() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 id = 2;
        uint256 amount = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id, amount, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC1155: transfer to the zero address"));
        ERC1155Extended.safeTransferFrom(owner, address(0), id, amount, data);
        vm.stopPrank();
    }

    function testSafeBatchTransferFromEOAReceiver() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(owner, owner, receiver, ids, amounts);
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.balanceOf(owner, ids[i]), 0);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeBatchTransferFromByApprovedOperator() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        address operator = vm.addr(3);
        bool approved = true;
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(operator, owner, receiver, ids, amounts);
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.balanceOf(owner, ids[i]), 0);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
            assertEq(ERC1155Extended.balanceOf(operator, ids[i]), 0);
        }
        vm.stopPrank();
    }

    function testSafeBatchTransferFromByNotApprovedOperator() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        address operator = vm.addr(3);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectRevert(
            bytes("ERC1155: caller is not token owner or approved")
        );
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        vm.stopPrank();
    }

    function testSafeBatchTransferFromNoData() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(owner, owner, receiver, ids, amounts);
        vm.expectEmit(true, true, false, true, receiver);
        emit BatchReceived(owner, owner, ids, amounts, data);
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.balanceOf(owner, ids[i]), 0);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeBatchTransferFromWithData() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(42);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(owner, owner, receiver, ids, amounts);
        vm.expectEmit(true, true, false, true, receiver);
        emit BatchReceived(owner, owner, ids, amounts, data);
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.balanceOf(owner, ids[i]), 0);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeBatchTransferFromReceiverInvalidReturnIdentifier() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = 0x00bb8833;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        vm.stopPrank();
    }

    function testSafeBatchTransferFromReceiverReverts() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = 0x00bb8833;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            true
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(
            bytes("ERC1155ReceiverMock: reverting on batch receive")
        );
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        vm.stopPrank();
    }

    function testSafeBatchTransferFromReceiverFunctionNotImplemented() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert();
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            deployer,
            ids,
            amounts,
            data
        );
        vm.stopPrank();
    }

    function testSafeBatchTransferFromReceiverRevertsOnlySingle() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            true,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(owner, owner, receiver, ids, amounts);
        vm.expectEmit(true, true, false, true, receiver);
        emit BatchReceived(owner, owner, ids, amounts, data);
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids,
            amounts,
            data
        );
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.balanceOf(owner, ids[i]), 0);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeBatchTransferFromInsufficientBalance() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        ++amounts[3];
        vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            vm.addr(2),
            ids,
            amounts,
            data
        );
        vm.stopPrank();
    }

    function testSafeBatchTransferFromLengthsMismatch() public {
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256[] memory ids1 = new uint256[](4);
        uint256[] memory ids2 = new uint256[](3);
        uint256[] memory amounts1 = new uint256[](3);
        uint256[] memory amounts2 = new uint256[](4);
        bytes memory data = new bytes(0);

        ids1[0] = 0;
        ids1[1] = 1;
        ids1[2] = 5;
        ids1[3] = 8;
        ids2[0] = 0;
        ids2[1] = 1;
        ids2[2] = 5;
        amounts1[0] = 1;
        amounts1[1] = 2;
        amounts1[2] = 10;
        amounts2[0] = 1;
        amounts2[1] = 2;
        amounts2[2] = 10;
        amounts2[2] = 20;

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids1,
            amounts1,
            data
        );
        vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            receiver,
            ids2,
            amounts2,
            data
        );
        vm.stopPrank();
    }

    function testSafeBatchTransferFromToZeroAddress() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC1155: transfer to the zero address"));
        ERC1155Extended.safeBatchTransferFrom(
            owner,
            address(0),
            ids,
            amounts,
            data
        );
        vm.stopPrank();
    }

    function testUriNoTokenUri() public {
        assertEq(
            ERC1155Extended.uri(0),
            string.concat(_BASE_URI, Strings.toString(uint256(0)))
        );
        assertEq(
            ERC1155Extended.uri(1),
            string.concat(_BASE_URI, Strings.toString(uint256(1)))
        );
    }

    function testUriNoBaseURI() public {
        bytes memory args = abi.encode("");
        ERC1155ExtendedNoBaseURI = IERC1155Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC1155", args)
        );
        string memory uri = "my_awesome_uri";
        uint256 id = 1;
        vm.prank(address(vyperDeployer));
        ERC1155ExtendedNoBaseURI.set_uri(id, uri);
        assertEq(ERC1155ExtendedNoBaseURI.uri(id), uri);
    }

    function testUriBaseAndTokenUriSet() public {
        string memory uri = "my_awesome_uri";
        uint256 id = 1;
        vm.prank(address(vyperDeployer));
        ERC1155Extended.set_uri(id, uri);
        assertEq(ERC1155Extended.uri(id), string.concat(_BASE_URI, uri));
    }

    function testUriBaseAndTokenUriNotSet() public {
        bytes memory args = abi.encode("");
        ERC1155ExtendedNoBaseURI = IERC1155Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC1155", args)
        );
        uint256 id = 1;
        assertEq(ERC1155ExtendedNoBaseURI.uri(id), "");
    }

    function testSetUri() public {
        string memory uri = "my_awesome_uri";
        uint256 id = 1;
        vm.prank(address(vyperDeployer));
        vm.expectEmit(true, false, false, true);
        emit URI(string.concat(_BASE_URI, uri), id);
        ERC1155Extended.set_uri(id, uri);
        assertEq(ERC1155Extended.uri(id), string.concat(_BASE_URI, uri));
    }

    function testSetUriEmpty() public {
        string memory uri = "";
        uint256 id = 1;
        vm.prank(address(vyperDeployer));
        vm.expectEmit(true, false, false, true);
        emit URI(string.concat(_BASE_URI, Strings.toString(uint256(id))), id);
        ERC1155Extended.set_uri(id, uri);
        assertEq(
            ERC1155Extended.uri(id),
            string.concat(_BASE_URI, Strings.toString(uint256(id)))
        );
    }

    function testSetUriNonMinter() public {
        vm.expectRevert(bytes("AccessControl: access is denied"));
        vm.prank(vm.addr(1));
        ERC1155Extended.set_uri(1, "my_awesome_uri");
    }

    function testTotalSupplyBeforeMint() public {
        assertEq(ERC1155Extended.total_supply(0), 0);
    }

    function testTotalSupplyAfterSingleMint() public {
        uint256 id = 0;
        bytes memory data = new bytes(0);
        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint(vm.addr(1), id, 1, data);
        ERC1155Extended.safe_mint(vm.addr(2), id, 20, data);
        assertEq(ERC1155Extended.total_supply(0), 21);
        vm.stopPrank();
    }

    function testTotalSupplyAfterBatchMint() public {
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 0;
        ids[3] = 1;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint_batch(vm.addr(1), ids, amounts, new bytes(0));
        assertEq(ERC1155Extended.total_supply(0), 11);
        assertEq(ERC1155Extended.total_supply(1), 22);
        vm.stopPrank();
    }

    function testTotalSupplyAfterSingleBurn() public {
        address owner = vm.addr(1);
        uint256 id = 0;
        bytes memory data = new bytes(0);
        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint(owner, id, 15, data);
        ERC1155Extended.safe_mint(vm.addr(2), id, 20, data);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC1155Extended.burn(owner, id, 10);
        assertEq(ERC1155Extended.total_supply(0), 25);
        vm.stopPrank();
    }

    function testTotalSupplyAfterBatchBurn() public {
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 0;
        ids[3] = 1;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, new bytes(0));
        vm.stopPrank();
        vm.startPrank(owner);
        --amounts[2];
        ERC1155Extended.burn_batch(owner, ids, amounts);
        assertEq(ERC1155Extended.total_supply(0), 1);
        assertEq(ERC1155Extended.total_supply(1), 0);
        vm.stopPrank();
    }

    function testExistsBeforeMint() public {
        assertTrue(!ERC1155Extended.exists(0));
    }

    function testExistsAfterSingleMint() public {
        uint256 id = 0;
        bytes memory data = new bytes(0);
        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint(vm.addr(1), id, 1, data);
        ERC1155Extended.safe_mint(vm.addr(2), id, 20, data);
        assertTrue(ERC1155Extended.exists(0));
        vm.stopPrank();
    }

    function testExistsAfterBatchMint() public {
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 0;
        ids[3] = 1;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint_batch(vm.addr(1), ids, amounts, new bytes(0));
        assertTrue(ERC1155Extended.exists(0));
        assertTrue(ERC1155Extended.exists(1));
        vm.stopPrank();
    }

    function testExistsAfterSingleBurn() public {
        address owner = vm.addr(1);
        uint256 id = 0;
        bytes memory data = new bytes(0);
        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint(owner, id, 15, data);
        ERC1155Extended.safe_mint(vm.addr(2), id, 20, data);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC1155Extended.burn(owner, id, 10);
        assertTrue(ERC1155Extended.exists(0));
        assertTrue(!ERC1155Extended.exists(1));
        vm.stopPrank();
    }

    function testExistsAfterBatchBurn() public {
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 0;
        ids[3] = 1;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, new bytes(0));
        vm.stopPrank();
        vm.startPrank(owner);
        --amounts[2];
        ERC1155Extended.burn_batch(owner, ids, amounts);
        assertTrue(ERC1155Extended.exists(0));
        assertTrue(!ERC1155Extended.exists(1));
        vm.stopPrank();
    }

    function testBurnSuccess() public {
        address firstOwner = vm.addr(1);
        address secondOwner = vm.addr(2);
        uint256 id = 0;
        uint256 burnAmount = 10;
        bytes memory data = new bytes(0);
        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint(firstOwner, id, 15, data);
        ERC1155Extended.safe_mint(secondOwner, id, 20, data);
        vm.stopPrank();
        vm.startPrank(firstOwner);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(firstOwner, firstOwner, address(0), id, burnAmount);
        ERC1155Extended.burn(firstOwner, id, 10);
        assertEq(ERC1155Extended.total_supply(0), 25);
        assertEq(ERC1155Extended.balanceOf(firstOwner, id), 5);
        assertEq(ERC1155Extended.balanceOf(secondOwner, id), 20);
        vm.stopPrank();
    }

    function testBurnByApprovedOperator() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        bool approved = true;
        uint256 id1 = 1;
        uint256 amount1 = 15;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        uint256 burnAmount = 10;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(operator, owner, address(0), id1, burnAmount);
        ERC1155Extended.burn(owner, id1, burnAmount);
        assertEq(ERC1155Extended.total_supply(id1), amount1 - burnAmount);
        assertEq(ERC1155Extended.total_supply(id2), amount2);
        assertEq(ERC1155Extended.balanceOf(owner, id1), amount1 - burnAmount);
        assertEq(ERC1155Extended.balanceOf(owner, id2), amount2);
        assertEq(ERC1155Extended.balanceOf(operator, id1), 0);
        assertEq(ERC1155Extended.balanceOf(operator, id2), 0);
        vm.stopPrank();
    }

    function testBurnByNotApprovedOperator() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        uint256 id1 = 1;
        uint256 amount1 = 15;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        uint256 burnAmount = 10;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(owner, id1, amount1, data);
        ERC1155Extended.safe_mint(owner, id2, amount2, data);
        vm.stopPrank();
        vm.startPrank(operator);
        vm.expectRevert(
            bytes("ERC1155: caller is not token owner or approved")
        );
        ERC1155Extended.burn(owner, id1, burnAmount);
        vm.stopPrank();
    }

    function testBurnFromZeroAddress() public {
        address owner = address(0);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC1155: burn from the zero address"));
        ERC1155Extended.burn(owner, 1, 1);
    }

    function testBurnAmountExceedsBalance() public {
        address firstOwner = vm.addr(1);
        address secondOwner = vm.addr(2);
        uint256 id = 0;
        bytes memory data = new bytes(0);
        vm.startPrank(address(vyperDeployer));
        ERC1155Extended.safe_mint(firstOwner, id, 15, data);
        ERC1155Extended.safe_mint(secondOwner, id, 20, data);
        vm.stopPrank();
        vm.startPrank(firstOwner);
        vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));
        ERC1155Extended.burn(firstOwner, id, 16);
        vm.stopPrank();
    }

    function testBurnNonExistentTokenId() public {
        address firstOwner = vm.addr(1);
        vm.prank(vm.addr(1));
        vm.expectRevert(bytes("ERC1155: burn amount exceeds total_supply"));
        ERC1155Extended.burn(firstOwner, 1, 1);
    }

    function testBurnBatch() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();
        vm.startPrank(owner);
        --amounts[2];
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(owner, owner, address(0), ids, amounts);
        ERC1155Extended.burn_batch(owner, ids, amounts);
        assertEq(ERC1155Extended.total_supply(ids[0]), 0);
        assertEq(ERC1155Extended.total_supply(ids[1]), 0);
        assertEq(ERC1155Extended.total_supply(ids[2]), 1);
        assertEq(ERC1155Extended.total_supply(ids[3]), 0);
        assertEq(ERC1155Extended.balanceOf(owner, ids[0]), 0);
        assertEq(ERC1155Extended.balanceOf(owner, ids[1]), 0);
        assertEq(ERC1155Extended.balanceOf(owner, ids[2]), 1);
        assertEq(ERC1155Extended.balanceOf(owner, ids[3]), 0);
        vm.stopPrank();
    }

    function testBurnBatchByApprovedOperator() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        bool approved = true;
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, data);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        --amounts[2];
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(operator, owner, address(0), ids, amounts);
        ERC1155Extended.burn_batch(owner, ids, amounts);
        assertEq(ERC1155Extended.total_supply(ids[0]), 0);
        assertEq(ERC1155Extended.total_supply(ids[1]), 0);
        assertEq(ERC1155Extended.total_supply(ids[2]), 1);
        assertEq(ERC1155Extended.total_supply(ids[3]), 0);
        assertEq(ERC1155Extended.balanceOf(owner, ids[0]), 0);
        assertEq(ERC1155Extended.balanceOf(owner, ids[1]), 0);
        assertEq(ERC1155Extended.balanceOf(owner, ids[2]), 1);
        assertEq(ERC1155Extended.balanceOf(owner, ids[3]), 0);
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.balanceOf(operator, ids[i]), 0);
        }
        vm.stopPrank();
    }

    function testBurnBatchByNotApprovedOperator() public {
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(operator);
        vm.expectRevert(
            bytes("ERC1155: caller is not token owner or approved")
        );
        ERC1155Extended.burn_batch(owner, ids, amounts);
        vm.stopPrank();
    }

    function testBurnBatchLengthsMismatch() public {
        address owner = vm.addr(1);
        uint256[] memory ids1 = new uint256[](4);
        uint256[] memory ids2 = new uint256[](3);
        uint256[] memory amounts1 = new uint256[](3);
        uint256[] memory amounts2 = new uint256[](4);

        ids1[0] = 0;
        ids1[1] = 1;
        ids1[2] = 5;
        ids1[3] = 8;
        ids2[0] = 0;
        ids2[1] = 1;
        ids2[2] = 5;
        amounts1[0] = 1;
        amounts1[1] = 2;
        amounts1[2] = 10;
        amounts2[0] = 1;
        amounts2[1] = 2;
        amounts2[2] = 10;
        amounts2[2] = 20;

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));
        ERC1155Extended.burn_batch(owner, ids1, amounts1);
        vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));
        ERC1155Extended.burn_batch(owner, ids2, amounts2);
        vm.stopPrank();
    }

    function testBurnBatchFromZeroAddress() public {
        address owner = address(0);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.prank(owner);
        vm.expectRevert(bytes("ERC1155: burn from the zero address"));
        ERC1155Extended.burn_batch(owner, ids, amounts);
    }

    function testBurnBatchAmountExceedsBalance() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address nonOwner = vm.addr(2);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        ERC1155Extended.safe_mint_batch(owner, ids, amounts, new bytes(0));
        vm.stopPrank();
        vm.startPrank(nonOwner);
        vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));
        ERC1155Extended.burn_batch(nonOwner, ids, amounts);
        vm.stopPrank();
    }

    function testBurnBatchNonExistentTokenIds() public {
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.prank(owner);
        vm.expectRevert(bytes("ERC1155: burn amount exceeds total_supply"));
        ERC1155Extended.burn_batch(owner, ids, amounts);
    }

    function testSafeMintEOAReceiver() public {
        address deployer = address(vyperDeployer);
        address receiver = vm.addr(1);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(deployer, address(0), receiver, id1, amount1);
        ERC1155Extended.safe_mint(receiver, id1, amount1, data);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(deployer, address(0), receiver, id2, amount2);
        ERC1155Extended.safe_mint(receiver, id2, amount2, data);
        assertEq(ERC1155Extended.total_supply(id1), amount1);
        assertEq(ERC1155Extended.total_supply(id2), amount2);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), amount2);
        vm.stopPrank();
    }

    function testSafeMintNoData() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(deployer, address(0), receiver, id1, amount1);
        ERC1155Extended.safe_mint(receiver, id1, amount1, data);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(deployer, address(0), receiver, id2, amount2);
        ERC1155Extended.safe_mint(receiver, id2, amount2, data);
        assertEq(ERC1155Extended.total_supply(id1), amount1);
        assertEq(ERC1155Extended.total_supply(id2), amount2);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), amount2);
        vm.stopPrank();
    }

    function testSafeMintWithData() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(42);
        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(deployer, address(0), receiver, id1, amount1);
        ERC1155Extended.safe_mint(receiver, id1, amount1, data);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(deployer, address(0), receiver, id2, amount2);
        ERC1155Extended.safe_mint(receiver, id2, amount2, data);
        assertEq(ERC1155Extended.total_supply(id1), amount1);
        assertEq(ERC1155Extended.total_supply(id2), amount2);
        assertEq(ERC1155Extended.balanceOf(receiver, id1), amount1);
        assertEq(ERC1155Extended.balanceOf(receiver, id2), amount2);
        vm.stopPrank();
    }

    function testSafeMintReceiverInvalidReturnIdentifier() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = 0x00bb8833;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );
        ERC1155Extended.safe_mint(receiver, id1, amount1, data);
        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );
        ERC1155Extended.safe_mint(receiver, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeMintReceiverReverts() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            true,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        vm.expectRevert(bytes("ERC1155ReceiverMock: reverting on receive"));
        ERC1155Extended.safe_mint(receiver, id1, amount1, data);
        vm.expectRevert(bytes("ERC1155ReceiverMock: reverting on receive"));
        ERC1155Extended.safe_mint(receiver, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeMintReceiverFunctionNotImplemented() public {
        address deployer = address(vyperDeployer);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        vm.expectRevert();
        ERC1155Extended.safe_mint(deployer, id1, amount1, data);
        vm.expectRevert();
        ERC1155Extended.safe_mint(deployer, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeMintToZeroAddress() public {
        address deployer = address(vyperDeployer);
        address receiver = address(0);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        vm.expectRevert(bytes("ERC1155: mint to the zero address"));
        ERC1155Extended.safe_mint(receiver, id1, amount1, data);
        vm.expectRevert(bytes("ERC1155: mint to the zero address"));
        ERC1155Extended.safe_mint(receiver, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeMintNonMinter() public {
        address receiver = vm.addr(1);
        uint256 id1 = 1;
        uint256 amount1 = 1;
        uint256 id2 = 4;
        uint256 amount2 = 15;
        bytes memory data = new bytes(0);
        vm.startPrank(vm.addr(2));
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC1155Extended.safe_mint(receiver, id1, amount1, data);
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC1155Extended.safe_mint(receiver, id2, amount2, data);
        vm.stopPrank();
    }

    function testSafeMintOverflow() public {
        address deployer = address(vyperDeployer);
        address receiver = vm.addr(1);
        uint256 id = 1;
        uint256 amount = type(uint256).max;
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(deployer, address(0), receiver, id, amount);
        ERC1155Extended.safe_mint(receiver, id, amount, data);
        vm.expectRevert();
        ERC1155Extended.safe_mint(receiver, id, amount, data);
        vm.stopPrank();
    }

    function testSafeMintBatchEOAReceiver() public {
        address deployer = address(vyperDeployer);
        address receiver = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(deployer, address(0), receiver, ids, amounts);
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.total_supply(ids[i]), amounts[i]);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeMintBatchNoData() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(deployer, address(0), receiver, ids, amounts);
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.total_supply(ids[i]), amounts[i]);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeMintBatchWithData() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(42);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(deployer, address(0), receiver, ids, amounts);
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.total_supply(ids[i]), amounts[i]);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeMintBatchReceiverInvalidReturnIdentifier() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = 0x00bb8833;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        vm.stopPrank();
    }

    function testSafeMintBatchReceiverReverts() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = 0x00bb8833;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            false,
            receiverBatchMagicValue,
            true
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectRevert(
            bytes("ERC1155ReceiverMock: reverting on batch receive")
        );
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        vm.stopPrank();
    }

    function testSafeMintBatchReceiverFunctionNotImplemented() public {
        address deployer = address(vyperDeployer);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectRevert();
        ERC1155Extended.safe_mint_batch(deployer, ids, amounts, data);
        vm.stopPrank();
    }

    function testSafeMintBatchReceiverRevertsOnlySingle() public {
        address deployer = address(vyperDeployer);
        bytes4 receiverSingleMagicValue = IERC1155Receiver
            .onERC1155Received
            .selector;
        bytes4 receiverBatchMagicValue = IERC1155Receiver
            .onERC1155BatchReceived
            .selector;
        ERC1155ReceiverMock erc1155ReceiverMock = new ERC1155ReceiverMock(
            receiverSingleMagicValue,
            true,
            receiverBatchMagicValue,
            false
        );
        address receiver = address(erc1155ReceiverMock);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(deployer, address(0), receiver, ids, amounts);
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        for (uint256 i; i < ids.length; ++i) {
            assertEq(ERC1155Extended.total_supply(ids[i]), amounts[i]);
            assertEq(ERC1155Extended.balanceOf(receiver, ids[i]), amounts[i]);
        }
        vm.stopPrank();
    }

    function testSafeMintBatchLengthsMismatch() public {
        address deployer = address(vyperDeployer);
        uint256[] memory ids1 = new uint256[](3);
        uint256[] memory ids2 = new uint256[](4);
        uint256[] memory amounts1 = new uint256[](4);
        uint256[] memory amounts2 = new uint256[](3);
        bytes memory data = new bytes(0);

        ids1[0] = 0;
        ids1[1] = 1;
        ids1[2] = 5;
        ids2[0] = 0;
        ids2[1] = 1;
        ids2[2] = 5;
        ids2[3] = 8;
        amounts1[0] = 1;
        amounts1[1] = 2;
        amounts1[2] = 10;
        amounts1[3] = 20;
        amounts2[0] = 1;
        amounts2[1] = 2;
        amounts2[2] = 10;

        vm.startPrank(deployer);
        vm.expectRevert("ERC1155: ids and amounts length mismatch");
        ERC1155Extended.safe_mint_batch(deployer, ids1, amounts1, data);
        vm.expectRevert("ERC1155: ids and amounts length mismatch");
        ERC1155Extended.safe_mint_batch(deployer, ids2, amounts2, data);
        vm.stopPrank();
    }

    function testSafeMintBatchToZeroAddress() public {
        address deployer = address(vyperDeployer);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(deployer);
        vm.expectRevert(bytes("ERC1155: mint to the zero address"));
        ERC1155Extended.safe_mint_batch(address(0), ids, amounts, data);
        vm.stopPrank();
    }

    function testSafeMintBatchNonMinter() public {
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;

        vm.startPrank(vm.addr(1));
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC1155Extended.safe_mint_batch(vm.addr(2), ids, amounts, data);
        vm.stopPrank();
    }

    function testSafeMintBatchOverflow() public {
        address deployer = address(vyperDeployer);
        address receiver = vm.addr(1);
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 5;
        ids[3] = 8;
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = type(uint256).max;

        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(deployer, address(0), receiver, ids, amounts);
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        vm.expectRevert();
        ERC1155Extended.safe_mint_batch(receiver, ids, amounts, data);
        vm.stopPrank();
    }

    function testSetMinterSuccess() public {
        address owner = address(vyperDeployer);
        address minter = vm.addr(1);
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, true);
        ERC1155Extended.set_minter(minter, true);
        assertTrue(ERC1155Extended.is_minter(minter));

        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, false);
        ERC1155Extended.set_minter(minter, false);
        assertTrue(!ERC1155Extended.is_minter(minter));
        vm.stopPrank();
    }

    function testSetMinterNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC1155Extended.set_minter(vm.addr(1), true);
    }

    function testSetMinterToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: minter is the zero address"));
        ERC1155Extended.set_minter(address(0), true);
    }

    function testSetMinterRemoveOwnerAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: minter is owner address"));
        ERC1155Extended.set_minter(address(vyperDeployer), false);
    }

    function testHasOwner() public {
        assertEq(ERC1155Extended.owner(), address(vyperDeployer));
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner, true);
        ERC1155Extended.transfer_ownership(newOwner);
        assertEq(ERC1155Extended.owner(), newOwner);
        assertTrue(!ERC1155Extended.is_minter(oldOwner));
        assertTrue(ERC1155Extended.is_minter(newOwner));
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC1155Extended.transfer_ownership(vm.addr(1));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("Ownable: new owner is the zero address"));
        ERC1155Extended.transfer_ownership(address(0));
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = address(0);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC1155Extended.renounce_ownership();
        assertEq(ERC1155Extended.owner(), newOwner);
        assertTrue(!ERC1155Extended.is_minter(oldOwner));
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC1155Extended.renounce_ownership();
    }
}
