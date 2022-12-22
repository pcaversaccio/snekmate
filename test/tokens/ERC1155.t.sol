// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC1565} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "openzeppelin/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import {Address} from "openzeppelin/utils/Address.sol";
import {ERC115ReceiverMock, ShouldRevert} from "./mocks/ERC1155ReceiverMock.sol";
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

    event URI(string value, uint256 indexed value);

    event OwnershipTransferred(address indexed previous_owner, address indexed new_owner);

    event RoleMinterChanged(address indexed minter, bool status);

    function setUp() public {
        bytes memory args = abi.encode(_BASE_URI);

        erc1155MetadataURI = IERC1155Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC1155", args)
        );
    }

    function testSupportsInterfaceSuccess() public {
        assertTrue(erc1155.supportsInterface(type(IERC165).interfaceId));
        assertTrue(erc1155.supportsInterface(type(IERC1155).interfaceId));
        assertTrue(erc1155.supportsInterface(type(IERC1155MetadataURI).interfaceId));
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

    // https://eips.ethereum.org/EIPS/eip-1155#safe-transfer-rules
    function testSafeTransferFromScenario1() public {
        // transfser to EOA
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
        assertEq(erc1155.balanceof(receiver, id), amount);
    }

    function testSafeTransferFromScenario2() public {}

    function testSafeTransferFromScenario3() public {}

    function testSafeTransferFromScenario4() public {}

    function testSafeTransferFromScenario5() public {}

    function testSafeTransferFromScenario6() public {}

    function testSafeTransferFromScenario7() public {}

    function testSafeTransferFromScenario8() public {}

    function testSafeTransferFromScenario9() public {}

    function testSafeTransferFromNotAuthorizedToTransfer() public {}

    function testSafeTransferFromTransferToZeroAddress() public {}

    function testSafeTransferFromTransferInsufficientBalance() public {}

    function testSafeBatchTransferFrom() public {}

    function testSafeBatchTransferFromScenario1() public {}

    function testSafeBatchTransferFromScenario2() public {}

    function testSafeBatchTransferFromScenario3() public {}

    function testSafeBatchTransferFromScenario4() public {}

    function testSafeBatchTransferFromScenario5() public {}

    function testSafeBatchTransferFromScenario6() public {}

    function testSafeBatchTransferFromScenario7() public {}

    function testSafeBatchTransferFromScenario8() public {}

    function testSafeBatchTransferFromScenario9() public {}

    function testSafeBatchTransferFromBatchLengthsMismatch() public {}

    function testSafeBatchTransferFromNotAuthorizedToTransfer() public {}

    function testSafeBatchTransferFromTransferToZeroAddress() public {}

    function testSafeBatchTransferFromTransferInsufficientBalance() public {}

    function testBalanceOf() public {}

    function testBalanceOfBatch() public {}

    function testBalanceOfBatchBatchLengthsMismatch() public {}

    function testSetApprovalForAll() public {}

    function testSetApprovalForAllApproveToCaller() public {}

    function testUri() public {}

    function testOwner() public {}

    function testTransferOwnership() public {}

    function testTransferOwnershipNotAuthorized() public {}

    function testTransferOwnershipZeroAddress() public {}

    function testRenounceOwnership() public {}

    function testRenounceOwnershipNotAuthorized() public {}

    function testIsMinter() public {}

    function testSetMinter() public {}

    function testSetMinterNotAuthorized() public {}

    function testSetMinterMinterIsZeroAddress() public {}

    function testSetMinterMinterIsOwnerAddress() public {}

    function testSetUri() public {}

    function testSetUriNotAuthorized() public {}

    function testSafeMint() public {}

    function testSafeMintNotMinter() public {}

    function testSafeMintMintToZeroAddress() public {}
}
