// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "openzeppelin/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import {ERC1155ReceiverMock} from "./mocks/ERC1155ReceiverMock.sol";

import {IERC1155Extended} from "./interfaces/IERC1155Extended.sol";

contract ERC1155Test is Test {
    string private constant _BASE_URI = "https://www.wagmi.xyz/";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC1155Extended private ERC1155Extended;

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
        bytes memory data = new bytes(0);
        vm.startPrank(deployer);
        ERC1155Extended.safe_mint(firstOwner, 0, 1, data);
        ERC1155Extended.safe_mint(secondOwner, 1, 20, data);
        assertEq(ERC1155Extended.balanceOf(firstOwner, 0), 1);
        assertEq(ERC1155Extended.balanceOf(secondOwner, 1), 20);
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC1155Extended.isApprovedForAll(owner, operator));

        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC1155Extended.isApprovedForAll(owner, operator));

        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
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
        vm.expectEmit(true, true, true, true, address(ERC1155Extended));
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true, address(ERC1155Extended));
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
        vm.expectEmit(true, true, true, true, address(ERC1155Extended));
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true, address(ERC1155Extended));
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
        vm.expectEmit(true, true, true, true, address(ERC1155Extended));
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
        emit ApprovalForAll(owner, operator, approved);
        ERC1155Extended.setApprovalForAll(operator, approved);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, true, address(ERC1155Extended));
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
        bytes memory data = new bytes(42);
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
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
        bytes memory data = new bytes(42);
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
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
        bytes memory data = new bytes(42);
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
        vm.expectEmit(true, true, false, true, address(ERC1155Extended));
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
        ERC1155Extended.safeTransferFrom(
            owner,
            vm.addr(2),
            id,
            amount + 1,
            data
        );
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

    // function testSafeBatchTransferFromReceiverNotAContract() public {
    //     //batch transfer to EOA
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = vm.addr(2);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferBatch(owner, owner, receiver, ids, amounts);

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);

    //     for (uint256 i; i < ids.length; ++i) {
    //         assertEq(erc1155.balanceOf(owner, ids[i]), 0);
    //         assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
    //     }
    // }

    // function testSafeBatchTransferFromByOperator() public {
    //     //batch transfer to EOA
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = vm.addr(2);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.prank(owner);
    //     erc1155.setApprovalForAll(receiver, true);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferBatch(receiver, owner, receiver, ids, amounts);

    //     vm.prank(receiver);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);

    //     for (uint256 i; i < ids.length; ++i) {
    //         assertEq(erc1155.balanceOf(owner, ids[i]), 0);
    //         assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
    //     }
    // }

    // function testSafeBatchTransferFromReceiverDoesNotImplementHook() public {
    //     //batch transfer to contract that does not implement onERC1155BatchReceived
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = address(new ERC1155NonReceiverMock());
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     //Revert is due to `ERC1155NoneReceiverMock` dispatcher not matching the function signature.
    //     vm.expectRevert();

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    // }

    // function testSafeBatchTransferFromReceiverReturnsInvalidValue() public {
    //     //batch transfer to contract that implements onERC1155Received but returns invalid value
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = address(
    //         new ERC1155InvalidReceiverMock({shouldThrow: false})
    //     );
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectRevert(
    //         bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
    //     );

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    // }

    // function testSafeBatchTransferFromReceiverRevertsInHook() public {
    //     //batch transfer to contract that implements onERC1155Received but reverts
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = address(
    //         new ERC1155InvalidReceiverMock({shouldThrow: true})
    //     );
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             ERC1155InvalidReceiverMock.Throw.selector,
    //             receiver
    //         )
    //     );

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    // }

    // function testSafeBatchTransferFromReceiverImplementsHook() public {
    //     //batch transfer to contract that implements onERC1155BatchReceived
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = address(new ERC1155ReceiverMock());
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferBatch(owner, owner, receiver, ids, amounts);

    //     vm.expectEmit(true, true, false, true, receiver);
    //     emit BatchReceived(owner, owner, ids, amounts, data);

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);

    //     for (uint256 i; i < ids.length; ++i) {
    //         assertEq(erc1155.balanceOf(owner, ids[i]), 0);
    //         assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
    //     }
    // }

    // function testSafeBatchTransferFromBatchLengthsMismatch() public {
    //     //batch transfer with mismatched array lengths
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = vm.addr(2);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](1);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, ids[0], 1, data);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, ids[1], 1, data);

    //     vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    // }

    // function testSafeBatchTransferFromCallerIsNotOwnerOrApproved() public {
    //     //batch transfer without authorization
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = vm.addr(2);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectRevert(
    //         bytes("ERC1155: caller is not token owner or approved")
    //     );

    //     vm.prank(receiver);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    // }

    // function testSafeBatchTransferFromTransferToZeroAddress() public {
    //     //batch transfer to zero address
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = address(0);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectRevert(bytes("ERC1155: transfer to the zero address"));

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    // }

    // function testSafeBatchTransferFromTransferInsufficientBalance() public {
    //     //batch transfer to zero address
    //     address owner = vm.addr(1);
    //     address receiver = vm.addr(2);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));

    //     vm.prank(owner);
    //     erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    // }

    // function testUriEmptyBaseUri() public {
    //     //uri read non-empty token uri, empty base uri
    //     address deployer = address(vyperDeployer);
    //     uint256 id = 1;
    //     string memory testUri = "test_uri";

    //     IERC1155Extended _erc1155 = IERC1155Extended(
    //         vyperDeployer.deployContract(
    //             "src/tokens/",
    //             "ERC1155",
    //             abi.encode("")
    //         )
    //     );

    //     vm.prank(deployer);
    //     _erc1155.set_uri(id, testUri);

    //     assertEq(bytes(_erc1155.uri(id)), bytes(testUri));
    // }

    // function testUriBaseAndTokenUriSet() public {
    //     //uri read non-empty token uri, non-empty base uri
    //     address deployer = address(vyperDeployer);
    //     uint256 id = 1;
    //     string memory testUri = "test_uri";

    //     vm.prank(deployer);
    //     erc1155.set_uri(id, testUri);

    //     assertEq(
    //         bytes(erc1155.uri(id)),
    //         bytes(string.concat(_BASE_URI, testUri))
    //     );
    // }

    // function testUriBaseUriNoTokenUriSet() public {
    //     //uri read empty token uri, non-empty base uri
    //     uint256 id = 1;

    //     assertEq(bytes(erc1155.uri(id)), bytes(string.concat(_BASE_URI, "1")));
    // }

    // function testUriEmptyBaseNoTokenUriSet() public {
    //     //uri read empty token uri, empty base uri
    //     uint256 id = 1;

    //     IERC1155Extended _erc1155 = IERC1155Extended(
    //         vyperDeployer.deployContract(
    //             "src/tokens/",
    //             "ERC1155",
    //             abi.encode("")
    //         )
    //     );

    //     assertEq(bytes(_erc1155.uri(id)), bytes(""));
    // }

    // function testIsMinter() public {
    //     //is minter read
    //     assertTrue(erc1155.is_minter(address(vyperDeployer)));
    //     assertFalse(erc1155.is_minter(vm.addr(1)));
    // }

    // function testSetMinter() public {
    //     //set minter
    //     address deployer = address(vyperDeployer);
    //     address minter = vm.addr(1);

    //     vm.expectEmit(true, false, false, true, address(erc1155));
    //     emit RoleMinterChanged(minter, true);

    //     vm.prank(deployer);
    //     erc1155.set_minter(minter, true);

    //     assertTrue(erc1155.is_minter(minter));
    // }

    // function testSetMinterCallerIsNotOwner() public {
    //     //set minter unauthorized
    //     address unauthorized = vm.addr(1);

    //     vm.expectRevert(bytes("Ownable: caller is not the owner"));

    //     vm.prank(unauthorized);
    //     erc1155.set_minter(unauthorized, true);
    // }

    // function testSetMinterMinterIsOwnerAddress() public {
    //     //set minter to self
    //     address deployer = address(vyperDeployer);

    //     vm.expectRevert(bytes("AccessControl: minter is owner address"));

    //     vm.prank(deployer);
    //     erc1155.set_minter(deployer, true);
    // }

    // function testSetMinterMinterIsZeroAddress() public {
    //     //set minter to zero address
    //     address deployer = address(vyperDeployer);

    //     vm.expectRevert(bytes("AccessControl: minter is the zero address"));

    //     vm.prank(deployer);
    //     erc1155.set_minter(address(0), true);
    // }

    // function testSetUri() public {
    //     //set uri
    //     address deployer = address(vyperDeployer);
    //     uint256 id = 1;
    //     string memory testUri = "test_uri";

    //     vm.expectEmit(true, false, false, true, address(erc1155));
    //     emit URI(string(abi.encodePacked(_BASE_URI, testUri)), id);

    //     vm.prank(deployer);
    //     erc1155.set_uri(id, testUri);

    //     assertEq(bytes(erc1155.uri(id)), abi.encodePacked(_BASE_URI, testUri));
    // }

    // function testSetUriAccessIsDenied() public {
    //     //set uri unauthorized
    //     address unauthorized = vm.addr(1);
    //     uint256 id = 1;
    //     string memory testUri = "test_uri";

    //     vm.expectRevert(bytes("AccessControl: access is denied"));

    //     vm.prank(unauthorized);
    //     erc1155.set_uri(id, testUri);
    // }

    // function testSafeMintReceiverNotAContract() public {
    //     //mint to EOA
    //     address deployer = address(vyperDeployer);
    //     address receiver = vm.addr(1);
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     assertEq(erc1155.total_supply(id), 0);
    //     assertEq(erc1155.balanceOf(receiver, id), 0);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferSingle(deployer, address(0), receiver, id, amount);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(receiver, id, amount, data);

    //     assertEq(erc1155.total_supply(id), amount);
    //     assertEq(erc1155.balanceOf(receiver, id), amount);
    // }

    // function testSafeMintNotMinter() public {
    //     //mint unauthorized
    //     address unauthorized = vm.addr(1);
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.expectRevert(bytes("AccessControl: access is denied"));

    //     vm.prank(unauthorized);
    //     erc1155.safe_mint(unauthorized, id, amount, data);
    // }

    // function testSafeMintMintToZeroAddress() public {
    //     //mint to zero address
    //     address deployer = address(vyperDeployer);
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.expectRevert(bytes("ERC1155: mint to the zero address"));

    //     vm.prank(deployer);
    //     erc1155.safe_mint(address(0), id, amount, data);
    // }

    // function testSafeMintReceiverDoesNotImplementHook() public {
    //     //mint receiver does not implement onERC1155Received
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(new ERC1155NonReceiverMock());
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     //Revert is due to `ERC1155NoneReceiverMock` dispatcher not matching the function signature.
    //     vm.expectRevert();

    //     vm.prank(deployer);
    //     erc1155.safe_mint(receiver, id, amount, data);
    // }

    // function testSafeMintReceiverReturnsInvalidvalue() public {
    //     //mint receiver implements onERC1155Received but returns invalid value
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(
    //         new ERC1155InvalidReceiverMock({shouldThrow: false})
    //     );
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.expectRevert(
    //         bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
    //     );

    //     vm.prank(deployer);
    //     erc1155.safe_mint(receiver, id, amount, data);
    // }

    // function testSafeMintReceiverRevertsInHook() public {
    //     //mint receiver implements onERC1155Received but reverts
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(
    //         new ERC1155InvalidReceiverMock({shouldThrow: true})
    //     );
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             ERC1155InvalidReceiverMock.Throw.selector,
    //             receiver
    //         )
    //     );

    //     vm.prank(deployer);
    //     erc1155.safe_mint(receiver, id, amount, data);
    // }

    // function testSafeMintReceiverImplementsHook() public {
    //     //mint receiver implements onERC1155Received
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(new ERC1155ReceiverMock());
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferSingle(deployer, address(0), receiver, id, amount);

    //     vm.expectEmit(true, true, false, true, receiver);
    //     emit Received(deployer, address(0), id, amount, data);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(receiver, id, amount, data);

    //     assertEq(erc1155.total_supply(id), amount);
    //     assertEq(erc1155.balanceOf(receiver, id), amount);
    // }

    // function testSafeMintBatchReceiverNotAContract() public {
    //     //mint batch to EOA
    //     address deployer = address(vyperDeployer);
    //     address receiver = vm.addr(1);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferBatch(deployer, address(0), receiver, ids, amounts);

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(receiver, ids, amounts, data);

    //     for (uint256 i; i < ids.length; ++i) {
    //         assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
    //         assertEq(erc1155.total_supply(ids[i]), amounts[i]);
    //     }
    // }

    // function testSafeMintBatchReceiverDoesNotImplementHook() public {
    //     //mint receiver does not implement onERC1155BatchReceived
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(new ERC1155NonReceiverMock());
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     //Revert is due to `ERC1155NoneReceiverMock` dispatcher not matching the function signature.
    //     vm.expectRevert();

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(receiver, ids, amounts, data);
    // }

    // function testSafeMintBatchReceiverReturnsInvalidValue() public {
    //     //mint batch receiver implements onERC1155BatchReceived but returns invalid value
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(
    //         new ERC1155InvalidReceiverMock({shouldThrow: false})
    //     );
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.expectRevert(
    //         bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
    //     );

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(receiver, ids, amounts, data);
    // }

    // function testSafeMintBatchReceiverRevertsInHook() public {
    //     //mint batch receiver implements onERC1155BatchReceived but reverts
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(
    //         new ERC1155InvalidReceiverMock({shouldThrow: true})
    //     );
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             ERC1155InvalidReceiverMock.Throw.selector,
    //             receiver
    //         )
    //     );

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(receiver, ids, amounts, data);
    // }

    // function testSafeMintBatchReceiverImplementsHook() public {
    //     //mint batch receiver implements onERC1155BatchReceived
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address receiver = address(new ERC1155ReceiverMock());
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferBatch(deployer, address(0), receiver, ids, amounts);

    //     vm.expectEmit(true, true, false, true, receiver);
    //     emit BatchReceived(deployer, address(0), ids, amounts, data);

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(receiver, ids, amounts, data);

    //     for (uint256 i; i < ids.length; ++i) {
    //         assertEq(erc1155.total_supply(ids[i]), amounts[i]);
    //         assertEq(erc1155.balanceOf(owner, ids[i]), amounts[i]);
    //     }
    // }

    // function testSafeMintBatchAccessIsDenied() public {
    //     //mint batch access denied
    //     address unauthorized = vm.addr(1);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.expectRevert(bytes("AccessControl: access is denied"));

    //     vm.prank(unauthorized);
    //     erc1155.safe_mint_batch(unauthorized, ids, amounts, data);
    // }

    // function testSafeMintBatchLengthsMismatch() public {
    //     //mint batch ids and amounts length mismatch
    //     address deployer = address(vyperDeployer);
    //     address receiver = vm.addr(1);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](1);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;

    //     vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(receiver, ids, amounts, data);
    // }

    // function testSafeMintBatchMintToZeroAddress() public {
    //     //mint batch to zero address
    //     address deployer = address(vyperDeployer);
    //     address receiver = address(0);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 0;
    //     ids[1] = 1;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.expectRevert(bytes("ERC1155: mint to the zero address"));

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(receiver, ids, amounts, data);
    // }

    // function testBurn() public {
    //     //burn
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, id, amount, data);

    //     assertEq(erc1155.total_supply(id), amount);
    //     assertEq(erc1155.balanceOf(owner, id), amount);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferSingle(owner, owner, address(0), id, amount);

    //     vm.prank(owner);
    //     erc1155.burn(owner, id, amount);

    //     assertEq(erc1155.total_supply(id), 0);
    //     assertEq(erc1155.balanceOf(owner, id), 0);
    // }

    // function testBurnByOperator() public {
    //     //burn by operator
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address operator = vm.addr(2);
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, id, amount, data);

    //     vm.prank(owner);
    //     erc1155.setApprovalForAll(operator, true);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferSingle(operator, owner, address(0), id, amount);

    //     vm.prank(operator);
    //     erc1155.burn(owner, id, amount);

    //     assertEq(erc1155.total_supply(id), 0);
    //     assertEq(erc1155.balanceOf(owner, id), 0);
    // }

    // function testBurnCallerNotOwnerOrApproved() public {
    //     //burn caller not owner or approved
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address unauthorized = vm.addr(2);
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, id, amount, data);

    //     vm.expectRevert(
    //         bytes("ERC1155: caller is not token owner or approved")
    //     );

    //     vm.prank(unauthorized);
    //     erc1155.burn(owner, id, amount);
    // }

    // function testBurnFromZeroAddress() public {
    //     //burn from zero address
    //     //NOTE this is the first check after authorization. so if this test
    //     //fails in the future as a result of adding a check or reordering the
    //     //checks, this is why. there appears to be no way to do this test
    //     //without dependence on either the order of checks or the storage layout
    //     address owner = address(0);
    //     uint256 id = 1;
    //     uint256 amount = 1;

    //     vm.expectRevert(bytes("ERC1155: burn from the zero address"));

    //     vm.prank(owner);
    //     erc1155.burn(owner, id, amount);
    // }

    // function testBurnAmountExceedsBalance() public {
    //     //burn amount exceeds balance
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address nonOwner = vm.addr(2);
    //     uint256 id = 1;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, id, amount, data);

    //     vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));

    //     vm.prank(nonOwner);
    //     erc1155.burn(nonOwner, id, amount);
    // }

    // function testBurnBatch() public {
    //     //burn batch
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 1;
    //     ids[1] = 2;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferBatch(owner, owner, address(0), ids, amounts);

    //     vm.prank(owner);
    //     erc1155.burn_batch(owner, ids, amounts);

    //     for (uint256 i; i < ids.length; ++i) {
    //         assertEq(erc1155.total_supply(ids[i]), 0);
    //         assertEq(erc1155.balanceOf(owner, ids[i]), 0);
    //     }
    // }

    // function testBurnBatchByOperator() public {
    //     //burn batch by operator
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 1;
    //     ids[1] = 2;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.prank(owner);
    //     erc1155.setApprovalForAll(deployer, true);

    //     vm.expectEmit(true, true, true, true, address(erc1155));
    //     emit TransferBatch(deployer, owner, address(0), ids, amounts);

    //     vm.prank(deployer);
    //     erc1155.burn_batch(owner, ids, amounts);

    //     for (uint256 i; i < ids.length; ++i) {
    //         assertEq(erc1155.total_supply(ids[i]), 0);
    //         assertEq(erc1155.balanceOf(owner, ids[i]), 0);
    //     }
    // }

    // function testBurnBatchCallerNotOwnerOrApproved() public {
    //     //burn batch caller not owner or approved
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address unauthorized = vm.addr(2);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 1;
    //     ids[1] = 2;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectRevert(
    //         bytes("ERC1155: caller is not token owner or approved")
    //     );

    //     vm.prank(unauthorized);
    //     erc1155.burn_batch(owner, ids, amounts);
    // }

    // function testBurnBatchLengthsMismatch() public {
    //     //burn batch ids and amounts lengths mismatch
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](1);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 1;
    //     ids[1] = 2;
    //     amounts[0] = 1;

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, ids[0], 1, data);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, ids[1], 1, data);

    //     vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));

    //     vm.prank(owner);
    //     erc1155.burn_batch(owner, ids, amounts);
    // }

    // function testBurnBatchFromZeroAddress() public {
    //     //burn batch from zero address
    //     //NOTE this is the first check after authorization and array length check.
    //     //so if this test fails in the future as a result of adding a check or
    //     //reordering the checks, this is why. there appears to be no way to do
    //     //this test without dependence on either the order of checks or the
    //     //storage layout
    //     address owner = address(0);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);

    //     ids[0] = 1;
    //     ids[1] = 2;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.expectRevert(bytes("ERC1155: burn from the zero address"));

    //     vm.prank(owner);
    //     erc1155.burn_batch(owner, ids, amounts);
    // }

    // function testBurnBatchAmountExceedsBalance() public {
    //     //burn batch amount exceeds balance
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     address nonOwner = vm.addr(2);
    //     uint256[] memory ids = new uint256[](2);
    //     uint256[] memory amounts = new uint256[](2);
    //     bytes memory data = new bytes(0);

    //     ids[0] = 1;
    //     ids[1] = 2;
    //     amounts[0] = 1;
    //     amounts[1] = 2;

    //     vm.prank(deployer);
    //     erc1155.safe_mint_batch(owner, ids, amounts, data);

    //     vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));

    //     vm.prank(nonOwner);
    //     erc1155.burn_batch(nonOwner, ids, amounts);
    // }

    // function testExists() public {
    //     //test token id total supply is nonzero
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     uint256 id = 1;
    //     uint256 otherId = 2;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     assertFalse(erc1155.exists(id));
    //     assertFalse(erc1155.exists(otherId));

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, id, amount, data);

    //     assertTrue(erc1155.exists(id));
    //     assertFalse(erc1155.exists(otherId));
    // }

    // function testTotalSupply() public {
    //     //test total supply
    //     address deployer = address(vyperDeployer);
    //     address owner = vm.addr(1);
    //     uint256 id = 1;
    //     uint256 otherId = 2;
    //     uint256 amount = 1;
    //     bytes memory data = new bytes(0);

    //     assertEq(erc1155.total_supply(id), 0);
    //     assertEq(erc1155.total_supply(otherId), 0);

    //     vm.prank(deployer);
    //     erc1155.safe_mint(owner, id, amount, data);

    //     assertEq(erc1155.total_supply(id), amount);
    //     assertEq(erc1155.total_supply(otherId), 0);
    // }

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
