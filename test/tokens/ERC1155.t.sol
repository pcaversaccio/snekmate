// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "openzeppelin/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import {Address} from "openzeppelin/utils/Address.sol";
import {ERC1155ReceiverMock} from "./mocks/ERC1155ReceiverMock.sol";
import {ERC1155InvalidReceiverMock} from "./mocks/ERC1155InvalidReceiverMock.sol";
import {ERC1155NonReceiverMock} from "./mocks/ERC1155NonReceiverMock.sol";
import {IERC1155Extended} from "./interfaces/IERC1155Extended.sol";

contract ERC1155Test is Test {
    string private constant _BASE_URI = "https://www.wagmi.xyz/";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IERC1155Extended private erc1155;

    event TransferSingle(
        address indexed operator,
        address indexed owner,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed owner,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    event URI(string value, uint256 indexed id);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event RoleMinterChanged(address indexed minter, bool status);

    function setUp() public {
        bytes memory args = abi.encode(_BASE_URI);

        erc1155 = IERC1155Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC1155", args)
        );
    }

    function testSupportsInterfaceSuccess() public {
        assertTrue(erc1155.supportsInterface(type(IERC165).interfaceId));
        assertTrue(erc1155.supportsInterface(type(IERC1155).interfaceId));
        assertTrue(
            erc1155.supportsInterface(type(IERC1155MetadataURI).interfaceId)
        );
    }

    function testSupportsInterfaceGasCost() public {
        uint256 startGas = gasleft();
        erc1155.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(gasUsed < 30_000);
    }

    function testSupportsInterfaceInvalidInterfaceId() public {
        assertTrue(!erc1155.supportsInterface(0x0011bbff));
    }

    function testSafeTransferFromReceiverNotAContract() public {
        //transfer to EOA
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferSingle(owner, owner, receiver, id, amount);

        vm.prank(owner);
        erc1155.safeTransferFrom(owner, receiver, id, amount, data);

        assertEq(erc1155.balanceOf(owner, id), 0);
        assertEq(erc1155.balanceOf(receiver, id), amount);
    }

    function testSafeTransferFromByOperator() public {
        //transfer to EOA
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.prank(owner);
        erc1155.setApprovalForAll(receiver, true);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferSingle(receiver, owner, receiver, id, amount);

        vm.prank(receiver);
        erc1155.safeTransferFrom(owner, receiver, id, amount, data);

        assertEq(erc1155.balanceOf(owner, id), 0);
        assertEq(erc1155.balanceOf(receiver, id), amount);
    }

    function testSafeTransferFromReceiverDoesNotImplementHook() public {
        //transfer to contract that does not implement onERC1155Received
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(new ERC1155NonReceiverMock());
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        //Revert is due to `ERC1155NoneReceiverMock` dispatcher not matching the function signature.
        vm.expectRevert();

        vm.prank(owner);
        erc1155.safeTransferFrom(owner, receiver, id, amount, data);
    }

    function testSafeTransferFromReceiverReturnsInvalidValue() public {
        //transfer to contract that implements onERC1155Received but returns invalid value
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: false})
        );
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );

        vm.prank(owner);
        erc1155.safeTransferFrom(owner, receiver, id, amount, data);
    }

    function testSafeTransferFromReceiverRevertsInHook() public {
        //transfer to contract that implements onERC1155Received but reverts
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: true})
        );
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC1155InvalidReceiverMock.Throw.selector,
                receiver
            )
        );

        vm.prank(owner);
        erc1155.safeTransferFrom(owner, receiver, id, amount, data);
    }

    function testSafeTransferFromReceiverImplementsHook() public {
        //transfer to contract that implements onERC1155Received
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(new ERC1155ReceiverMock());
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferSingle(owner, owner, receiver, id, amount);

        vm.expectEmit(true, true, false, true, receiver);
        emit Received(owner, owner, id, amount, data);

        vm.prank(owner);
        erc1155.safeTransferFrom(owner, receiver, id, amount, data);

        assertEq(erc1155.balanceOf(owner, id), 0);
        assertEq(erc1155.balanceOf(receiver, id), amount);
    }

    function testSafeBatchTransferFromReceiverNotAContract() public {
        //batch transfer to EOA
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferBatch(owner, owner, receiver, ids, amounts);

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);

        for (uint256 i; i < ids.length; ++i) {
            assertEq(erc1155.balanceOf(owner, ids[i]), 0);
            assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
        }
    }

    function testSafeBatchTransferFromByOperator() public {
        //batch transfer to EOA
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.prank(owner);
        erc1155.setApprovalForAll(receiver, true);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferBatch(receiver, owner, receiver, ids, amounts);

        vm.prank(receiver);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);

        for (uint256 i; i < ids.length; ++i) {
            assertEq(erc1155.balanceOf(owner, ids[i]), 0);
            assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
        }
    }

    function testSafeBatchTransferFromReceiverDoesNotImplementHook() public {
        //batch transfer to contract that does not implement onERC1155BatchReceived
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(new ERC1155NonReceiverMock());
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        //Revert is due to `ERC1155NoneReceiverMock` dispatcher not matching the function signature.
        vm.expectRevert();

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    }

    function testSafeBatchTransferFromReceiverReturnsInvalidValue() public {
        //batch transfer to contract that implements onERC1155Received but returns invalid value
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: false})
        );
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    }

    function testSafeBatchTransferFromReceiverRevertsInHook() public {
        //batch transfer to contract that implements onERC1155Received but reverts
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: true})
        );
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC1155InvalidReceiverMock.Throw.selector,
                receiver
            )
        );

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    }

    function testSafeBatchTransferFromReceiverImplementsHook() public {
        //batch transfer to contract that implements onERC1155BatchReceived
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(new ERC1155ReceiverMock());
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferBatch(owner, owner, receiver, ids, amounts);

        vm.expectEmit(true, true, false, true, receiver);
        emit BatchReceived(owner, owner, ids, amounts, data);

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);

        for (uint256 i; i < ids.length; ++i) {
            assertEq(erc1155.balanceOf(owner, ids[i]), 0);
            assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
        }
    }

    function testSafeBatchTransferFromBatchLengthsMismatch() public {
        //batch transfer with mismatched array lengths
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](1);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;

        vm.prank(deployer);
        erc1155.safe_mint(owner, ids[0], 1, data);

        vm.prank(deployer);
        erc1155.safe_mint(owner, ids[1], 1, data);

        vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    }

    function testSafeBatchTransferFromCallerIsNotOwnerOrApproved() public {
        //batch transfer without authorization
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectRevert(
            bytes("ERC1155: caller is not token owner or approved")
        );

        vm.prank(receiver);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    }

    function testSafeBatchTransferFromTransferToZeroAddress() public {
        //batch transfer to zero address
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(0);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectRevert(bytes("ERC1155: transfer to the zero address"));

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    }

    function testSafeBatchTransferFromTransferInsufficientBalance() public {
        //batch transfer to zero address
        address owner = vm.addr(1);
        address receiver = vm.addr(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));

        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, receiver, ids, amounts, data);
    }

    function testBalanceOf() public {
        //balance read
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, 0, 1, data);

        assertEq(erc1155.balanceOf(owner, 0), 1);
        assertEq(erc1155.balanceOf(owner, 1), 0);
    }

    function testBalanceOfAddressZero() public {
        //balance read zero address
        vm.expectRevert(bytes("ERC1155: address zero is not a valid owner"));

        erc1155.balanceOf(address(0), 0);
    }

    function testBalanceOfBatch() public {
        //batch balance read
        address deployer = address(vyperDeployer);
        address[] memory owners = new address[](2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        owners[0] = vm.addr(1);
        owners[1] = vm.addr(1);
        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owners[0], ids, amounts, data);

        uint256[] memory balances = erc1155.balanceOfBatch(owners, ids);

        assertEq(balances.length, 2);

        for (uint256 i; i < balances.length; ++i) {
            assertEq(balances[i], amounts[i]);
        }
    }

    function testBalanceOfBatchBatchLengthsMismatch() public {
        //batch balance read owners and ids lengths mismatch
        address[] memory owners = new address[](2);
        uint256[] memory ids = new uint256[](1);

        owners[0] = vm.addr(1);
        owners[1] = vm.addr(2);
        ids[0] = 0;

        vm.expectRevert(bytes("ERC1155: owners and ids length mismatch"));
        erc1155.balanceOfBatch(owners, ids);
    }

    function testBalanceOfBatchZeroAddress() public {
        //batch balance read owners includes zero address
        address[] memory owners = new address[](1);
        uint256[] memory ids = new uint256[](1);

        owners[0] = address(0);
        ids[0] = 0;

        vm.expectRevert(bytes("ERC1155: address zero is not a valid owner"));

        erc1155.balanceOfBatch(owners, ids);
    }

    function testSetApprovalForAll() public {
        //set operator status
        address account = vm.addr(1);
        address operator = vm.addr(2);

        assertFalse(erc1155.isApprovedForAll(account, operator));

        vm.expectEmit(true, true, false, true, address(erc1155));
        emit ApprovalForAll(account, operator, true);

        vm.prank(account);
        erc1155.setApprovalForAll(operator, true);

        assertTrue(erc1155.isApprovedForAll(account, operator));
    }

    function testSetApprovalForAllRevoke() public {
        //set operator then revoke
        address account = vm.addr(1);
        address operator = vm.addr(2);

        vm.prank(account);
        erc1155.setApprovalForAll(operator, true);

        vm.expectEmit(true, true, false, true, address(erc1155));
        emit ApprovalForAll(account, operator, false);

        vm.prank(account);
        erc1155.setApprovalForAll(operator, false);

        assertFalse(erc1155.isApprovedForAll(account, operator));
    }

    function testSetApprovalForAllApproveToCaller() public {
        //set operator status to self
        address account = vm.addr(1);

        vm.expectRevert(bytes("ERC1155: setting approval status for self"));

        vm.prank(account);
        erc1155.setApprovalForAll(account, true);
    }

    function testUriEmptyBaseUri() public {
        //uri read non-empty token uri, empty base uri
        address deployer = address(vyperDeployer);
        uint256 id = 1;
        string memory testUri = "test_uri";

        IERC1155Extended _erc1155 = IERC1155Extended(
            vyperDeployer.deployContract(
                "src/tokens/",
                "ERC1155",
                abi.encode("")
            )
        );

        vm.prank(deployer);
        _erc1155.set_uri(id, testUri);

        assertEq(bytes(_erc1155.uri(id)), bytes(testUri));
    }

    function testUriBaseAndTokenUriSet() public {
        //uri read non-empty token uri, non-empty base uri
        address deployer = address(vyperDeployer);
        uint256 id = 1;
        string memory testUri = "test_uri";

        vm.prank(deployer);
        erc1155.set_uri(id, testUri);

        assertEq(
            bytes(erc1155.uri(id)),
            bytes(string.concat(_BASE_URI, testUri))
        );
    }

    function testUriBaseUriNoTokenUriSet() public {
        //uri read empty token uri, non-empty base uri
        uint256 id = 1;

        assertEq(bytes(erc1155.uri(id)), bytes(string.concat(_BASE_URI, "1")));
    }

    function testUriEmptyBaseNoTokenUriSet() public {
        //uri read empty token uri, empty base uri
        uint256 id = 1;

        IERC1155Extended _erc1155 = IERC1155Extended(
            vyperDeployer.deployContract(
                "src/tokens/",
                "ERC1155",
                abi.encode("")
            )
        );

        assertEq(bytes(_erc1155.uri(id)), bytes(""));
    }

    function testOwner() public {
        //owner read
        assertEq(erc1155.owner(), address(vyperDeployer));
    }

    function testTransferOwnership() public {
        //transfer ownership
        address deployer = address(vyperDeployer);
        address newOwner = vm.addr(1);

        vm.expectEmit(true, true, false, false, address(erc1155));
        emit OwnershipTransferred(deployer, newOwner);

        vm.prank(deployer);
        erc1155.transfer_ownership(newOwner);

        assertEq(erc1155.owner(), newOwner);
    }

    function testTransferOwnershipNotOwner() public {
        //transfer ownership by nauthorized
        address unauthorized = vm.addr(1);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));

        vm.prank(unauthorized);
        erc1155.transfer_ownership(unauthorized);
    }

    function testTransferOwnershipZeroAddress() public {
        //transfer ownership to zero address
        address deployer = address(vyperDeployer);

        vm.expectRevert(bytes("Ownable: new owner is the zero address"));

        vm.prank(deployer);
        erc1155.transfer_ownership(address(0));
    }

    function testRenounceOwnership() public {
        //renounce ownership
        address deployer = address(vyperDeployer);

        vm.expectEmit(true, true, false, false, address(erc1155));
        emit OwnershipTransferred(deployer, address(0));

        vm.prank(deployer);
        erc1155.renounce_ownership();

        assertEq(erc1155.owner(), address(0));
        assertFalse(erc1155.is_minter(deployer));
    }

    function testRenounceOwnershipNotOwner() public {
        //renounce ownership unauthorized
        address unauthorized = vm.addr(1);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));

        vm.prank(unauthorized);
        erc1155.renounce_ownership();
    }

    function testIsMinter() public {
        //is minter read
        assertTrue(erc1155.is_minter(address(vyperDeployer)));
        assertFalse(erc1155.is_minter(vm.addr(1)));
    }

    function testSetMinter() public {
        //set minter
        address deployer = address(vyperDeployer);
        address minter = vm.addr(1);

        vm.expectEmit(true, false, false, true, address(erc1155));
        emit RoleMinterChanged(minter, true);

        vm.prank(deployer);
        erc1155.set_minter(minter, true);

        assertTrue(erc1155.is_minter(minter));
    }

    function testSetMinterCallerIsNotOwner() public {
        //set minter unauthorized
        address unauthorized = vm.addr(1);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));

        vm.prank(unauthorized);
        erc1155.set_minter(unauthorized, true);
    }

    function testSetMinterMinterIsOwnerAddress() public {
        //set minter to self
        address deployer = address(vyperDeployer);

        vm.expectRevert(bytes("AccessControl: minter is owner address"));

        vm.prank(deployer);
        erc1155.set_minter(deployer, true);
    }

    function testSetMinterMinterIsZeroAddress() public {
        //set minter to zero address
        address deployer = address(vyperDeployer);

        vm.expectRevert(bytes("AccessControl: minter is the zero address"));

        vm.prank(deployer);
        erc1155.set_minter(address(0), true);
    }

    function testSetUri() public {
        //set uri
        address deployer = address(vyperDeployer);
        uint256 id = 1;
        string memory testUri = "test_uri";

        vm.expectEmit(true, false, false, true, address(erc1155));
        emit URI(string(abi.encodePacked(_BASE_URI, testUri)), id);

        vm.prank(deployer);
        erc1155.set_uri(id, testUri);

        assertEq(bytes(erc1155.uri(id)), abi.encodePacked(_BASE_URI, testUri));
    }

    function testSetUriAccessIsDenied() public {
        //set uri unauthorized
        address unauthorized = vm.addr(1);
        uint256 id = 1;
        string memory testUri = "test_uri";

        vm.expectRevert(bytes("AccessControl: access is denied"));

        vm.prank(unauthorized);
        erc1155.set_uri(id, testUri);
    }

    function testSafeMintReceiverNotAContract() public {
        //mint to EOA
        address deployer = address(vyperDeployer);
        address receiver = vm.addr(1);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        assertEq(erc1155.total_supply(id), 0);
        assertEq(erc1155.balanceOf(receiver, id), 0);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferSingle(deployer, address(0), receiver, id, amount);

        vm.prank(deployer);
        erc1155.safe_mint(receiver, id, amount, data);

        assertEq(erc1155.total_supply(id), amount);
        assertEq(erc1155.balanceOf(receiver, id), amount);
    }

    function testSafeMintNotMinter() public {
        //mint unauthorized
        address unauthorized = vm.addr(1);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.expectRevert(bytes("AccessControl: access is denied"));

        vm.prank(unauthorized);
        erc1155.safe_mint(unauthorized, id, amount, data);
    }

    function testSafeMintMintToZeroAddress() public {
        //mint to zero address
        address deployer = address(vyperDeployer);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.expectRevert(bytes("ERC1155: mint to the zero address"));

        vm.prank(deployer);
        erc1155.safe_mint(address(0), id, amount, data);
    }

    function testSafeMintReceiverDoesNotImplementHook() public {
        //mint receiver does not implement onERC1155Received
        address deployer = address(vyperDeployer);
        address receiver = address(new ERC1155NonReceiverMock());
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        //Revert is due to `ERC1155NoneReceiverMock` dispatcher not matching the function signature.
        vm.expectRevert();

        vm.prank(deployer);
        erc1155.safe_mint(receiver, id, amount, data);
    }

    function testSafeMintReceiverReturnsInvalidvalue() public {
        //mint receiver implements onERC1155Received but returns invalid value
        address deployer = address(vyperDeployer);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: false})
        );
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );

        vm.prank(deployer);
        erc1155.safe_mint(receiver, id, amount, data);
    }

    function testSafeMintReceiverRevertsInHook() public {
        //mint receiver implements onERC1155Received but reverts
        address deployer = address(vyperDeployer);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: true})
        );
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC1155InvalidReceiverMock.Throw.selector,
                receiver
            )
        );

        vm.prank(deployer);
        erc1155.safe_mint(receiver, id, amount, data);
    }

    function testSafeMintReceiverImplementsHook() public {
        //mint receiver implements onERC1155Received
        address deployer = address(vyperDeployer);
        address receiver = address(new ERC1155ReceiverMock());
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferSingle(deployer, address(0), receiver, id, amount);

        vm.expectEmit(true, true, false, true, receiver);
        emit Received(deployer, address(0), id, amount, data);

        vm.prank(deployer);
        erc1155.safe_mint(receiver, id, amount, data);

        assertEq(erc1155.total_supply(id), amount);
        assertEq(erc1155.balanceOf(receiver, id), amount);
    }

    function testSafeMintBatchReceiverNotAContract() public {
        //mint batch to EOA
        address deployer = address(vyperDeployer);
        address receiver = vm.addr(1);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferBatch(deployer, address(0), receiver, ids, amounts);

        vm.prank(deployer);
        erc1155.safe_mint_batch(receiver, ids, amounts, data);

        for (uint256 i; i < ids.length; ++i) {
            assertEq(erc1155.balanceOf(receiver, ids[i]), amounts[i]);
            assertEq(erc1155.total_supply(ids[i]), amounts[i]);
        }
    }

    function testSafeMintBatchReceiverDoesNotImplementHook() public {
        //mint receiver does not implement onERC1155BatchReceived
        address deployer = address(vyperDeployer);
        address receiver = address(new ERC1155NonReceiverMock());
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        //Revert is due to `ERC1155NoneReceiverMock` dispatcher not matching the function signature.
        vm.expectRevert();

        vm.prank(deployer);
        erc1155.safe_mint_batch(receiver, ids, amounts, data);
    }

    function testSafeMintBatchReceiverReturnsInvalidValue() public {
        //mint batch receiver implements onERC1155BatchReceived but returns invalid value
        address deployer = address(vyperDeployer);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: false})
        );
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.expectRevert(
            bytes("ERC1155: transfer to non-ERC1155Receiver implementer")
        );

        vm.prank(deployer);
        erc1155.safe_mint_batch(receiver, ids, amounts, data);
    }

    function testSafeMintBatchReceiverRevertsInHook() public {
        //mint batch receiver implements onERC1155BatchReceived but reverts
        address deployer = address(vyperDeployer);
        address receiver = address(
            new ERC1155InvalidReceiverMock({shouldThrow: true})
        );
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC1155InvalidReceiverMock.Throw.selector,
                receiver
            )
        );

        vm.prank(deployer);
        erc1155.safe_mint_batch(receiver, ids, amounts, data);
    }

    function testSafeMintBatchReceiverImplementsHook() public {
        //mint batch receiver implements onERC1155BatchReceived
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address receiver = address(new ERC1155ReceiverMock());
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferBatch(deployer, address(0), receiver, ids, amounts);

        vm.expectEmit(true, true, false, true, receiver);
        emit BatchReceived(deployer, address(0), ids, amounts, data);

        vm.prank(deployer);
        erc1155.safe_mint_batch(receiver, ids, amounts, data);

        for (uint256 i; i < ids.length; ++i) {
            assertEq(erc1155.total_supply(ids[i]), amounts[i]);
            assertEq(erc1155.balanceOf(owner, ids[i]), amounts[i]);
        }
    }

    function testSafeMintBatchAccessIsDenied() public {
        //mint batch access denied
        address unauthorized = vm.addr(1);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.expectRevert(bytes("AccessControl: access is denied"));

        vm.prank(unauthorized);
        erc1155.safe_mint_batch(unauthorized, ids, amounts, data);
    }

    function testSafeMintBatchLengthsMismatch() public {
        //mint batch ids and amounts length mismatch
        address deployer = address(vyperDeployer);
        address receiver = vm.addr(1);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](1);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;

        vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));

        vm.prank(deployer);
        erc1155.safe_mint_batch(receiver, ids, amounts, data);
    }

    function testSafeMintBatchMintToZeroAddress() public {
        //mint batch to zero address
        address deployer = address(vyperDeployer);
        address receiver = address(0);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.expectRevert(bytes("ERC1155: mint to the zero address"));

        vm.prank(deployer);
        erc1155.safe_mint_batch(receiver, ids, amounts, data);
    }

    function testBurn() public {
        //burn
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        assertEq(erc1155.total_supply(id), amount);
        assertEq(erc1155.balanceOf(owner, id), amount);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferSingle(owner, owner, address(0), id, amount);

        vm.prank(owner);
        erc1155.burn(owner, id, amount);

        assertEq(erc1155.total_supply(id), 0);
        assertEq(erc1155.balanceOf(owner, id), 0);
    }

    function testBurnByOperator() public {
        //burn by operator
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.prank(owner);
        erc1155.setApprovalForAll(operator, true);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferSingle(operator, owner, address(0), id, amount);

        vm.prank(operator);
        erc1155.burn(owner, id, amount);

        assertEq(erc1155.total_supply(id), 0);
        assertEq(erc1155.balanceOf(owner, id), 0);
    }

    function testBurnCallerNotOwnerOrApproved() public {
        //burn caller not owner or approved
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address unauthorized = vm.addr(2);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.expectRevert(
            bytes("ERC1155: caller is not token owner or approved")
        );

        vm.prank(unauthorized);
        erc1155.burn(owner, id, amount);
    }

    function testBurnFromZeroAddress() public {
        //burn from zero address
        //NOTE this is the first check after authorization. so if this test
        //fails in the future as a result of adding a check or reordering the
        //checks, this is why. there appears to be no way to do this test
        //without dependence on either the order of checks or the storage layout
        address owner = address(0);
        uint256 id = 1;
        uint256 amount = 1;

        vm.expectRevert(bytes("ERC1155: burn from the zero address"));

        vm.prank(owner);
        erc1155.burn(owner, id, amount);
    }

    function testBurnAmountExceedsBalance() public {
        //burn amount exceeds balance
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address nonOwner = vm.addr(2);
        uint256 id = 1;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));

        vm.prank(nonOwner);
        erc1155.burn(nonOwner, id, amount);
    }

    function testBurnBatch() public {
        //burn batch
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferBatch(owner, owner, address(0), ids, amounts);

        vm.prank(owner);
        erc1155.burn_batch(owner, ids, amounts);

        for (uint256 i; i < ids.length; ++i) {
            assertEq(erc1155.total_supply(ids[i]), 0);
            assertEq(erc1155.balanceOf(owner, ids[i]), 0);
        }
    }

    function testBurnBatchByOperator() public {
        //burn batch by operator
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.prank(owner);
        erc1155.setApprovalForAll(deployer, true);

        vm.expectEmit(true, true, true, true, address(erc1155));
        emit TransferBatch(deployer, owner, address(0), ids, amounts);

        vm.prank(deployer);
        erc1155.burn_batch(owner, ids, amounts);

        for (uint256 i; i < ids.length; ++i) {
            assertEq(erc1155.total_supply(ids[i]), 0);
            assertEq(erc1155.balanceOf(owner, ids[i]), 0);
        }
    }

    function testBurnBatchCallerNotOwnerOrApproved() public {
        //burn batch caller not owner or approved
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address unauthorized = vm.addr(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectRevert(
            bytes("ERC1155: caller is not token owner or approved")
        );

        vm.prank(unauthorized);
        erc1155.burn_batch(owner, ids, amounts);
    }

    function testBurnBatchLengthsMismatch() public {
        //burn batch ids and amounts lengths mismatch
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](1);
        bytes memory data = new bytes(0);

        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 1;

        vm.prank(deployer);
        erc1155.safe_mint(owner, ids[0], 1, data);

        vm.prank(deployer);
        erc1155.safe_mint(owner, ids[1], 1, data);

        vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));

        vm.prank(owner);
        erc1155.burn_batch(owner, ids, amounts);
    }

    function testBurnBatchFromZeroAddress() public {
        //burn batch from zero address
        //NOTE this is the first check after authorization and array length check.
        //so if this test fails in the future as a result of adding a check or
        //reordering the checks, this is why. there appears to be no way to do
        //this test without dependence on either the order of checks or the
        //storage layout
        address owner = address(0);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.expectRevert(bytes("ERC1155: burn from the zero address"));

        vm.prank(owner);
        erc1155.burn_batch(owner, ids, amounts);
    }

    function testBurnBatchAmountExceedsBalance() public {
        //burn batch amount exceeds balance
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address nonOwner = vm.addr(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        bytes memory data = new bytes(0);

        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        erc1155.safe_mint_batch(owner, ids, amounts, data);

        vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));

        vm.prank(nonOwner);
        erc1155.burn_batch(nonOwner, ids, amounts);
    }

    function testExists() public {
        //test token id total supply is nonzero
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 id = 1;
        uint256 otherId = 2;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        assertFalse(erc1155.exists(id));
        assertFalse(erc1155.exists(otherId));

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        assertTrue(erc1155.exists(id));
        assertFalse(erc1155.exists(otherId));
    }

    function testTotalSupply() public {
        //test total supply
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 id = 1;
        uint256 otherId = 2;
        uint256 amount = 1;
        bytes memory data = new bytes(0);

        assertEq(erc1155.total_supply(id), 0);
        assertEq(erc1155.total_supply(otherId), 0);

        vm.prank(deployer);
        erc1155.safe_mint(owner, id, amount, data);

        assertEq(erc1155.total_supply(id), amount);
        assertEq(erc1155.total_supply(otherId), 0);
    }
}
