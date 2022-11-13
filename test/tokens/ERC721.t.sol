// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {stdError} from "../../lib/forge-std/src/StdError.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IERC165} from "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC4494} from "./interfaces/IERC4494.sol";

import {Address} from "../../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {ERC721ReceiverMock} from "./mocks/ERC721ReceiverMock.sol";

import {IERC721Extended} from "../../test/tokens/interfaces/IERC721Extended.sol";

/**
 * Missing unit tests:
 *   - tokenByIndex
 *   - tokenOfOwnerByIndex
 *   - burn
 *   - safe_mint
 */
contract ERC721Test is Test {
    string private constant _NAME = "MyNFT";
    string private constant _SYMBOL = "WAGMI";
    string private constant _BASE_URI = "https://www.wagmi.xyz/";
    string private constant _NAME_EIP712 = "MyNFT";
    string private constant _VERSION_EIP712 = "1";
    bytes32 private constant _TYPE_HASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 private constant _PERMIT_TYPE_HASH =
        keccak256(
            bytes(
                "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
            )
        );

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC721Extended private ERC721Extended;
    // solhint-disable-next-line var-name-mixedcase
    IERC721Extended private ERC721ExtendedNoBaseURI;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _CACHED_DOMAIN_SEPARATOR;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Received(address operator, address from, uint256 tokenId, bytes data);

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event RoleMinterChanged(address indexed minter, bool status);

    /**
     * @dev An `internal` function that validates a successful transfer call.
     * @param owner The 20-byte owner address.
     * @param tokenId The 32-byte identifier of the token.
     * @param receiver The 20-byte receiver address.
     */
    function _transferSuccess(
        address owner,
        uint256 tokenId,
        address receiver
    ) internal {
        assertEq(ERC721Extended.ownerOf(tokenId), receiver);
        assertEq(ERC721Extended.getApproved(tokenId), address(0));
        assertEq(ERC721Extended.balanceOf(owner), 1);
        assertEq(ERC721Extended.balanceOf(receiver), 1);
        assertEq(ERC721Extended.tokenOfOwnerByIndex(receiver, 0), tokenId);
        assertTrue(ERC721Extended.tokenOfOwnerByIndex(owner, 0) != tokenId);
    }

    /**
     * @dev An `internal` function that validates all possible reverts
     * after an invalid transfer call.
     * @param transferFunction The transfer function including the type definitions
     * of the arguments.
     * @param owner The 20-byte owner address.
     * @param tokenId The 32-byte identifier of the token.
     * @param receiver The 20-byte receiver address.
     * @param withData The Boolean variable indicating whether additional
     * data is sent or not.
     * @param data The additional data with no specified format that is sent
     * to the `receiver`.
     */
    function _transferReverts(
        string memory transferFunction,
        address owner,
        uint256 tokenId,
        address receiver,
        bool withData,
        bytes memory data
    ) internal {
        vm.startPrank(vm.addr(5));
        vm.expectRevert(bytes("ERC721: caller is not token owner or approved"));
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId,
                    data
                )
            );
        }
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: transfer from incorrect owner"));
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    receiver,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    receiver,
                    receiver,
                    tokenId,
                    data
                )
            );
        }
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    receiver,
                    receiver,
                    tokenId + 2
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    receiver,
                    receiver,
                    tokenId + 2,
                    data
                )
            );
        }
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: transfer to the zero address"));
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    address(0),
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    address(0),
                    tokenId,
                    data
                )
            );
        }
        vm.stopPrank();
    }

    /**
     * @dev An `internal` function that validates all possible successful
     * and reverted transfer calls.
     * @param transferFunction The transfer function including the type definitions
     * of the arguments.
     * @param owner The 20-byte owner address.
     * @param approved The 20-byte approved address.
     * @param operator The 20-byte operator address.
     * @param tokenId The 32-byte identifier of the token.
     * @param receiver The 20-byte receiver address.
     * @param withData The Boolean variable indicating whether additional
     * data is sent or not.
     * @param data The additional data with no specified format that is sent
     * to the `receiver`.
     */
    function _shouldTransferTokensByUsers(
        string memory transferFunction,
        address owner,
        address approved,
        address operator,
        uint256 tokenId,
        address receiver,
        bool withData,
        bytes memory data
    ) internal {
        uint256 snapshot = vm.snapshot();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, receiver, tokenId);
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId,
                    data
                )
            );
        }
        _transferSuccess(owner, tokenId, receiver);
        vm.stopPrank();
        vm.revertTo(snapshot);

        snapshot = vm.snapshot();
        vm.startPrank(approved);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, receiver, tokenId);
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId,
                    data
                )
            );
        }
        _transferSuccess(owner, tokenId, receiver);
        vm.stopPrank();
        vm.revertTo(snapshot);

        snapshot = vm.snapshot();
        vm.startPrank(operator);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, receiver, tokenId);
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId,
                    data
                )
            );
        }
        _transferSuccess(owner, tokenId, receiver);
        vm.stopPrank();
        vm.revertTo(snapshot);

        snapshot = vm.snapshot();
        vm.startPrank(owner);
        ERC721Extended.approve(address(0), tokenId);
        vm.stopPrank();
        vm.startPrank(operator);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, receiver, tokenId);
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId,
                    data
                )
            );
        }
        _transferSuccess(owner, tokenId, receiver);
        vm.stopPrank();
        vm.revertTo(snapshot);

        snapshot = vm.snapshot();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, owner, tokenId);
        if (!withData) {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(transferFunction, owner, owner, tokenId)
            );
        } else {
            Address.functionCall(
                address(ERC721Extended),
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    owner,
                    tokenId,
                    data
                )
            );
        }
        assertEq(ERC721Extended.ownerOf(tokenId), owner);
        assertEq(ERC721Extended.getApproved(tokenId), address(0));
        assertEq(ERC721Extended.balanceOf(owner), 2);
        assertEq(ERC721Extended.tokenOfOwnerByIndex(owner, 0), tokenId);
        assertTrue(ERC721Extended.tokenOfOwnerByIndex(owner, 1) == tokenId + 1);
        vm.stopPrank();
        vm.revertTo(snapshot);

        /// @dev Validates all possible reverts.
        _transferReverts(
            transferFunction,
            owner,
            tokenId,
            receiver,
            withData,
            data
        );
    }

    /**
     * @dev An `internal` function that validates all possible successful
     * and reverted safe transfer calls.
     * @param transferFunction The transfer function including the type definitions
     * of the arguments.
     * @param owner The 20-byte owner address.
     * @param approved The 20-byte approved address.
     * @param operator The 20-byte operator address.
     * @param tokenId The 32-byte identifier of the token.
     * @param receiver The 20-byte receiver address.
     * @param data The additional data with no specified format that is sent
     * to the `receiver`.
     */
    function _shouldTransferSafely(
        string memory transferFunction,
        address owner,
        address approved,
        address operator,
        uint256 tokenId,
        address receiver,
        bytes memory data
    ) internal {
        uint256 snapshot = vm.snapshot();
        _shouldTransferTokensByUsers(
            transferFunction,
            owner,
            approved,
            operator,
            tokenId,
            vm.addr(6),
            true,
            data
        );
        vm.revertTo(snapshot);

        snapshot = vm.snapshot();
        _shouldTransferTokensByUsers(
            transferFunction,
            owner,
            approved,
            operator,
            tokenId,
            receiver,
            true,
            data
        );
        vm.revertTo(snapshot);

        snapshot = vm.snapshot();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true, receiver);
        emit Received(owner, owner, tokenId, data);
        Address.functionCall(
            address(ERC721Extended),
            abi.encodeWithSignature(
                transferFunction,
                owner,
                receiver,
                tokenId,
                data
            )
        );
        _transferSuccess(owner, tokenId, receiver);
        vm.stopPrank();
        vm.revertTo(snapshot);

        snapshot = vm.snapshot();
        vm.startPrank(approved);
        vm.expectEmit(true, true, true, true, receiver);
        emit Received(approved, owner, tokenId, data);
        Address.functionCall(
            address(ERC721Extended),
            abi.encodeWithSignature(
                transferFunction,
                owner,
                receiver,
                tokenId,
                data
            )
        );
        _transferSuccess(owner, tokenId, receiver);
        vm.stopPrank();
        vm.revertTo(snapshot);

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        Address.functionCall(
            address(ERC721Extended),
            abi.encodeWithSignature(
                transferFunction,
                owner,
                receiver,
                tokenId + 2,
                data
            )
        );
        vm.stopPrank();
    }

    function setUp() public {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _BASE_URI,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC721Extended = IERC721Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC721", args)
        );
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                address(ERC721Extended)
            )
        );
    }

    function testInitialSetup() public {
        address deployer = address(vyperDeployer);
        assertEq(ERC721Extended.name(), _NAME);
        assertEq(ERC721Extended.symbol(), _SYMBOL);
        assertTrue(ERC721Extended.owner() == deployer);
        assertTrue(ERC721Extended.is_minter(deployer));
    }

    function testSupportsInterfaceSuccess() public {
        assertTrue(ERC721Extended.supportsInterface(type(IERC165).interfaceId));
        assertTrue(ERC721Extended.supportsInterface(type(IERC721).interfaceId));
        assertTrue(
            ERC721Extended.supportsInterface(type(IERC721Metadata).interfaceId)
        );
        assertTrue(
            ERC721Extended.supportsInterface(
                type(IERC721Enumerable).interfaceId
            )
        );
        assertTrue(
            ERC721Extended.supportsInterface(type(IERC4494).interfaceId)
        );
    }

    function testSupportsInterfaceGasCost() public {
        uint256 startGas = gasleft();
        ERC721Extended.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(gasUsed < 30_000);
    }

    function testSupportsInterfaceInvalidInterfaceId() public {
        assertTrue(!ERC721Extended.supportsInterface(0x0011bbff));
    }

    function testBalanceOfCase1() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        assertEq(ERC721Extended.balanceOf(owner), 2);
        vm.stopPrank();
    }

    function testBalanceOfCase2() public {
        assertEq(ERC721Extended.balanceOf(vm.addr(1)), 0);
    }

    function testBalanceOfZeroAddress() public {
        vm.expectRevert(bytes("ERC721: the zero address is not a valid owner"));
        ERC721Extended.balanceOf(address(0));
    }

    function testOwnerOf() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        assertEq(ERC721Extended.ownerOf(0), owner);
        vm.stopPrank();
    }

    function testOwnerOfInvalidTokenId() public {
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.ownerOf(0);
    }

    function testTransferFrom() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address approved = vm.addr(2);
        address operator = vm.addr(3);
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC721Extended.approve(approved, 0);
        ERC721Extended.setApprovalForAll(operator, true);
        vm.stopPrank();
        _shouldTransferTokensByUsers(
            "transferFrom(address,address,uint256)",
            owner,
            approved,
            operator,
            0,
            vm.addr(4),
            false,
            new bytes(0)
        );
    }

    function testSafeTransferFromNoData() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address approved = vm.addr(2);
        address operator = vm.addr(3);
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.None
        );
        address receiver = address(erc721ReceiverMock);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC721Extended.approve(approved, 0);
        ERC721Extended.setApprovalForAll(operator, true);
        vm.stopPrank();
        _shouldTransferSafely(
            "safeTransferFrom(address,address,uint256,bytes)",
            owner,
            approved,
            operator,
            0,
            receiver,
            new bytes(0)
        );
    }

    function testSafeTransferFromWithData() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address approved = vm.addr(2);
        address operator = vm.addr(3);
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.None
        );
        address receiver = address(erc721ReceiverMock);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC721Extended.approve(approved, 0);
        ERC721Extended.setApprovalForAll(operator, true);
        vm.stopPrank();
        _shouldTransferSafely(
            "safeTransferFrom(address,address,uint256,bytes)",
            owner,
            approved,
            operator,
            0,
            receiver,
            new bytes(42)
        );
    }

    function testSafeTransferFromReceiverInvalidReturnIdentifier() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            0x00bb8833,
            ERC721ReceiverMock.Error.None
        );
        address receiver = address(erc721ReceiverMock);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(
            bytes("ERC721: transfer to non-ERC721Receiver implementer")
        );
        ERC721Extended.safeTransferFrom(owner, receiver, 0, new bytes(0));
        vm.stopPrank();
    }

    function testSafeTransferFromReceiverRevertsWithMessage() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.RevertWithMessage
        );
        address receiver = address(erc721ReceiverMock);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721ReceiverMock: reverting"));
        ERC721Extended.safeTransferFrom(owner, receiver, 0, new bytes(0));
        vm.stopPrank();
    }

    function testSafeTransferFromReceiverRevertsWithoutMessage() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.RevertWithoutMessage
        );
        address receiver = address(erc721ReceiverMock);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert();
        ERC721Extended.safeTransferFrom(owner, receiver, 0, new bytes(0));
        vm.stopPrank();
    }

    function testSafeTransferFromReceiverRevertsWithPanic() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.Panic
        );
        address receiver = address(erc721ReceiverMock);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(stdError.divisionError);
        ERC721Extended.safeTransferFrom(owner, receiver, 0, new bytes(0));
        vm.stopPrank();
    }

    function testSafeTransferFromReceiverFunctionNotImplemented() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert();
        ERC721Extended.safeTransferFrom(owner, deployer, 0, new bytes(0));
        vm.stopPrank();
    }

    function testApproveClearingApprovalWithNoPriorApproval() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = address(0);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender, tokenId);
        ERC721Extended.approve(spender, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender);
        vm.stopPrank();
    }

    function testApproveClearingApprovalWithPriorApproval() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender1 = vm.addr(2);
        address spender2 = address(0);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender1, tokenId);
        ERC721Extended.approve(spender1, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender1);

        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender2, tokenId);
        ERC721Extended.approve(spender2, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender2);
        vm.stopPrank();
    }

    function testApproveToZeroAddress() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender1 = vm.addr(2);
        address spender2 = address(0);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender1, tokenId);
        ERC721Extended.approve(spender1, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender1);

        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender2, tokenId);
        ERC721Extended.approve(spender2, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender2);
        vm.stopPrank();
    }

    function testApproveWithNoPriorApproval() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender, tokenId);
        ERC721Extended.approve(spender, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender);
        vm.stopPrank();
    }

    function testApproveWithPriorApprovalToSameAddress() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender, tokenId);
        ERC721Extended.approve(spender, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender);

        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender, tokenId);
        ERC721Extended.approve(spender, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender);
        vm.stopPrank();
    }

    function testApproveWithPriorApprovalToDifferentAddress() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender1 = vm.addr(2);
        address spender2 = vm.addr(3);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender1, tokenId);
        ERC721Extended.approve(spender1, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender1);

        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender2, tokenId);
        ERC721Extended.approve(spender2, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender2);
        vm.stopPrank();
    }

    function testApproveToOwner() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: approval to current owner"));
        ERC721Extended.approve(owner, tokenId);
        vm.stopPrank();
    }

    function testApproveFromNonOwner() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(vm.addr(2));
        vm.expectRevert(
            bytes(
                "ERC721: approve caller is not token owner or approved for all"
            )
        );
        ERC721Extended.approve(vm.addr(3), tokenId);
        vm.stopPrank();
    }

    function testApproveFromApprovedAddress() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC721Extended.approve(spender, tokenId);
        vm.stopPrank();
        vm.startPrank(spender);
        vm.expectRevert(
            bytes(
                "ERC721: approve caller is not token owner or approved for all"
            )
        );
        ERC721Extended.approve(vm.addr(3), tokenId);
        vm.stopPrank();
    }

    function testApproveFromOperatorAddress() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        address spender = vm.addr(3);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC721Extended.setApprovalForAll(operator, true);
        vm.stopPrank();
        vm.startPrank(operator);
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender, tokenId);
        ERC721Extended.approve(spender, tokenId);
        assertEq(ERC721Extended.getApproved(tokenId), spender);
        vm.stopPrank();
    }

    function testApproveInvalidTokenId() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.approve(vm.addr(2), tokenId + 1);
        vm.stopPrank();
    }

    function testSetApprovalForAllSuccessCase1() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        bool approved = true;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC721Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC721Extended.isApprovedForAll(owner, operator));
        vm.stopPrank();
    }

    function testSetApprovalForAllSuccessCase2() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        bool approved = true;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, !approved);
        ERC721Extended.setApprovalForAll(operator, !approved);
        assertTrue(!ERC721Extended.isApprovedForAll(owner, operator));

        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC721Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC721Extended.isApprovedForAll(owner, operator));

        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, !approved);
        ERC721Extended.setApprovalForAll(operator, !approved);
        assertTrue(!ERC721Extended.isApprovedForAll(owner, operator));
        vm.stopPrank();
    }

    function testSetApprovalForAllSuccessCase3() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address operator = vm.addr(2);
        bool approved = true;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC721Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC721Extended.isApprovedForAll(owner, operator));

        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        ERC721Extended.setApprovalForAll(operator, approved);
        assertTrue(ERC721Extended.isApprovedForAll(owner, operator));
        vm.stopPrank();
    }

    function testSetApprovalForAllOperatorIsOwner() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: approve to caller"));
        ERC721Extended.setApprovalForAll(owner, true);
        vm.stopPrank();
    }

    function testGetApprovedInvalidTokenId() public {
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.getApproved(0);
    }

    function testGetApprovedNotApprovedTokenId() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        assertEq(ERC721Extended.getApproved(0), address(0));
    }

    function testGetApprovedApprovedTokenId() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC721Extended.approve(spender, 0);
        assertEq(ERC721Extended.getApproved(0), spender);
        vm.stopPrank();
    }

    function testTokenURIDefault() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        assertEq(ERC721Extended.tokenURI(0), string.concat(_BASE_URI, uri));
    }

    function testTokenURINoTokenUri() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, "");
        vm.stopPrank();
        assertEq(ERC721Extended.tokenURI(0), string.concat(_BASE_URI, "0"));
    }

    function testTokenURINoBaseURI() public {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            "",
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC721ExtendedNoBaseURI = IERC721Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC721", args)
        );
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721ExtendedNoBaseURI.safe_mint(owner, uri);
        vm.stopPrank();
        assertEq(ERC721ExtendedNoBaseURI.tokenURI(0), uri);
    }

    function testTokenURIInvalidTokenId() public {
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.tokenURI(0);
    }

    function testTokenURIAfterBurning() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        vm.startPrank(owner);
        ERC721Extended.burn(0);
        vm.stopPrank();
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.tokenURI(0);
    }

    function testTotalSupply() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 2);
    }

    function testSetMinterSuccess() public {
        address owner = address(vyperDeployer);
        address minter = vm.addr(1);
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, true);
        ERC721Extended.set_minter(minter, true);
        assertTrue(ERC721Extended.is_minter(minter));

        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, false);
        ERC721Extended.set_minter(minter, false);
        assertTrue(!ERC721Extended.is_minter(minter));
        vm.stopPrank();
    }

    function testSetMinterNonOwner() public {
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ERC721Extended.set_minter(vm.addr(1), true);
    }

    function testSetMinterToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: minter is the zero address"));
        ERC721Extended.set_minter(address(0), true);
    }

    function testSetMinterRemoveOwnerAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: minter is owner address"));
        ERC721Extended.set_minter(address(vyperDeployer), false);
    }

    function testPermitSuccess() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spender,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender, tokenId);
        ERC721Extended.permit(spender, tokenId, deadline, v, r, s);
        assertEq(ERC721Extended.getApproved(tokenId), spender);
        assertEq(ERC721Extended.nonces(tokenId), 1);
    }

    function testPermitReplaySignature() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spender,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectEmit(true, true, true, false);
        emit Approval(owner, spender, tokenId);
        ERC721Extended.permit(spender, tokenId, deadline, v, r, s);
        vm.expectRevert(bytes("ERC721Permit: invalid signature"));
        ERC721Extended.permit(spender, tokenId, deadline, v, r, s);
    }

    function testPermitOtherSignature() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            3,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spender,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC721Permit: invalid signature"));
        ERC721Extended.permit(spender, tokenId, deadline, v, r, s);
    }

    function testPermitBadChainId() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid + 1,
                address(ERC721Extended)
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spender,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC721Permit: invalid signature"));
        ERC721Extended.permit(spender, tokenId, deadline, v, r, s);
    }

    function testPermitBadNonce() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        uint256 nonce = 1;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            3,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spender,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC721Permit: invalid signature"));
        ERC721Extended.permit(spender, tokenId, deadline, v, r, s);
    }

    function testPermitExpiredDeadline() public {
        address deployer = address(vyperDeployer);
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        uint256 nonce = 1;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp - 1;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            3,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spender,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC721Permit: expired deadline"));
        ERC721Extended.permit(spender, tokenId, deadline, v, r, s);
    }

    function testCachedDomainSeparator() public {
        assertEq(ERC721Extended.DOMAIN_SEPARATOR(), _CACHED_DOMAIN_SEPARATOR);
    }

    function testDomainSeparator() public {
        vm.chainId(block.chainid + 1);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                address(ERC721Extended)
            )
        );
        assertEq(ERC721Extended.DOMAIN_SEPARATOR(), digest);
    }

    function testHasOwner() public {
        assertEq(ERC721Extended.owner(), address(vyperDeployer));
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC721Extended.transfer_ownership(newOwner);
        assertEq(ERC721Extended.owner(), newOwner);
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ERC721Extended.transfer_ownership(vm.addr(1));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: new owner is the zero address"));
        ERC721Extended.transfer_ownership(address(0));
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = address(0);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC721Extended.renounce_ownership();
        assertEq(ERC721Extended.owner(), newOwner);
        assertTrue(ERC721Extended.is_minter(oldOwner) == false);
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ERC721Extended.renounce_ownership();
    }
}
