// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "openzeppelin/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC4494} from "./interfaces/IERC4494.sol";

import {Address} from "openzeppelin/utils/Address.sol";
import {ERC721ReceiverMock} from "./mocks/ERC721ReceiverMock.sol";

import {IERC721Extended} from "./interfaces/IERC721Extended.sol";

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

    /* solhint-disable var-name-mixedcase */
    IERC721Extended private ERC721Extended;
    IERC721Extended private ERC721ExtendedInitialEvent;
    IERC721Extended private ERC721ExtendedNoBaseURI;
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    /* solhint-enable var-name-mixedcase */

    address private deployer = address(vyperDeployer);
    address private zeroAddress = address(0);
    // solhint-disable-next-line var-name-mixedcase
    address private ERC721ExtendedAddr;

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

    event MetadataUpdate(uint256 tokenId);

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
        assertEq(ERC721Extended.getApproved(tokenId), zeroAddress);
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
        vm.startPrank(makeAddr("nonOwner"));
        vm.expectRevert(bytes("ERC721: caller is not token owner or approved"));
        if (!withData) {
            Address.functionCall(
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    receiver,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    receiver,
                    receiver,
                    tokenId + 2
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    zeroAddress,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    zeroAddress,
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
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
        ERC721Extended.approve(zeroAddress, tokenId);
        vm.stopPrank();
        vm.startPrank(operator);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, receiver, tokenId);
        if (!withData) {
            Address.functionCall(
                ERC721ExtendedAddr,
                abi.encodeWithSignature(
                    transferFunction,
                    owner,
                    receiver,
                    tokenId
                )
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
                ERC721ExtendedAddr,
                abi.encodeWithSignature(transferFunction, owner, owner, tokenId)
            );
        } else {
            Address.functionCall(
                ERC721ExtendedAddr,
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
        assertEq(ERC721Extended.getApproved(tokenId), zeroAddress);
        assertEq(ERC721Extended.balanceOf(owner), 2);
        assertEq(ERC721Extended.tokenOfOwnerByIndex(owner, 0), tokenId);
        assertTrue(ERC721Extended.tokenOfOwnerByIndex(owner, 1) == tokenId + 1);
        vm.stopPrank();
        vm.revertTo(snapshot);

        /**
         * @dev Validates all possible reverts.
         */
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
            makeAddr("receiver"),
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
            ERC721ExtendedAddr,
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
            ERC721ExtendedAddr,
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
            ERC721ExtendedAddr,
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
        ERC721ExtendedAddr = address(ERC721Extended);
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC721ExtendedAddr
            )
        );
    }

    function testInitialSetup() public {
        assertEq(ERC721Extended.name(), _NAME);
        assertEq(ERC721Extended.symbol(), _SYMBOL);
        assertEq(ERC721Extended.totalSupply(), 0);
        assertEq(ERC721Extended.owner(), deployer);
        assertTrue(ERC721Extended.is_minter(deployer));

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(zeroAddress, deployer);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(deployer, true);
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _BASE_URI,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC721ExtendedInitialEvent = IERC721Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC721", args)
        );
        assertEq(ERC721ExtendedInitialEvent.name(), _NAME);
        assertEq(ERC721ExtendedInitialEvent.symbol(), _SYMBOL);
        assertEq(ERC721ExtendedInitialEvent.totalSupply(), 0);
        assertEq(ERC721ExtendedInitialEvent.owner(), deployer);
        assertTrue(ERC721ExtendedInitialEvent.is_minter(deployer));
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
        assertTrue(ERC721Extended.supportsInterface(0x49064906));
    }

    function testSupportsInterfaceSuccessGasCost() public {
        uint256 startGas = gasleft();
        ERC721Extended.supportsInterface(type(IERC165).interfaceId);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(
            gasUsed <= 30_000 &&
                ERC721Extended.supportsInterface(type(IERC165).interfaceId)
        );
    }

    function testSupportsInterfaceInvalidInterfaceId() public {
        assertTrue(!ERC721Extended.supportsInterface(0x0011bbff));
    }

    function testSupportsInterfaceInvalidInterfaceIdGasCost() public {
        uint256 startGas = gasleft();
        ERC721Extended.supportsInterface(0x0011bbff);
        uint256 gasUsed = startGas - gasleft();
        assertTrue(
            gasUsed <= 30_000 && !ERC721Extended.supportsInterface(0x0011bbff)
        );
    }

    function testBalanceOfCase1() public {
        address owner = makeAddr("owner");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        assertEq(ERC721Extended.balanceOf(owner), 2);
        vm.stopPrank();
    }

    function testBalanceOfCase2() public {
        assertEq(ERC721Extended.balanceOf(makeAddr("owner")), 0);
    }

    function testBalanceOfZeroAddress() public {
        vm.expectRevert(bytes("ERC721: the zero address is not a valid owner"));
        ERC721Extended.balanceOf(zeroAddress);
    }

    function testOwnerOf() public {
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
        address approved = makeAddr("approved");
        address operator = makeAddr("operator");
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
            makeAddr("receiver"),
            false,
            new bytes(0)
        );
    }

    function testSafeTransferFromNoData() public {
        address owner = makeAddr("owner");
        address approved = makeAddr("approved");
        address operator = makeAddr("operator");
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

        _shouldTransferTokensByUsers(
            "safeTransferFrom(address,address,uint256)",
            owner,
            approved,
            operator,
            0,
            makeAddr("receiver"),
            false,
            new bytes(0)
        );

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
        address owner = makeAddr("owner");
        address approved = makeAddr("approved");
        address operator = makeAddr("operator");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
        address spender = zeroAddress;
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
        address owner = makeAddr("owner");
        address spender1 = makeAddr("spender1");
        address spender2 = zeroAddress;
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
        address owner = makeAddr("owner");
        address spender1 = makeAddr("spender1");
        address spender2 = zeroAddress;
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
        address owner = makeAddr("owner");
        address spender = makeAddr("spender");
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
        address owner = makeAddr("owner");
        address spender = makeAddr("spender");
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
        address owner = makeAddr("owner");
        address spender1 = makeAddr("spender1");
        address spender2 = makeAddr("spender2");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        vm.startPrank(makeAddr("nonOwner"));
        vm.expectRevert(
            bytes(
                "ERC721: approve caller is not token owner or approved for all"
            )
        );
        ERC721Extended.approve(makeAddr("to"), tokenId);
        vm.stopPrank();
    }

    function testApproveFromApprovedAddress() public {
        address owner = makeAddr("owner");
        address spender = makeAddr("spender");
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
        ERC721Extended.approve(makeAddr("to"), tokenId);
        vm.stopPrank();
    }

    function testApproveFromOperatorAddress() public {
        address owner = makeAddr("owner");
        address operator = makeAddr("operator");
        address spender = makeAddr("spender");
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
        address owner = makeAddr("owner");
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.approve(makeAddr("to"), tokenId + 1);
        vm.stopPrank();
    }

    function testSetApprovalForAllSuccessCase1() public {
        address owner = makeAddr("owner");
        address operator = makeAddr("operator");
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
        address owner = makeAddr("owner");
        address operator = makeAddr("operator");
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
        address owner = makeAddr("owner");
        address operator = makeAddr("operator");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        assertEq(ERC721Extended.getApproved(0), zeroAddress);
    }

    function testGetApprovedApprovedTokenId() public {
        address owner = makeAddr("owner");
        address spender = makeAddr("spender");
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
        address owner = makeAddr("owner");
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        assertEq(ERC721Extended.tokenURI(0), string.concat(_BASE_URI, uri));
    }

    function testTokenURINoTokenUri() public {
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
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
        address owner = makeAddr("owner");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 2);
    }

    function testTokenByIndex() public {
        address owner = makeAddr("owner");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        string memory uri3 = "my_awesome_nft_uri_3";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        ERC721Extended.safe_mint(owner, uri3);
        vm.stopPrank();
        assertEq(ERC721Extended.tokenByIndex(0), tokenId);
        assertEq(ERC721Extended.tokenByIndex(1), tokenId + 1);
        assertEq(ERC721Extended.tokenByIndex(2), tokenId + 2);
        assertEq(ERC721Extended.totalSupply(), 3);

        vm.startPrank(owner);
        ERC721Extended.burn(1);
        vm.stopPrank();
        assertEq(ERC721Extended.tokenByIndex(0), tokenId);
        assertEq(ERC721Extended.tokenByIndex(1), tokenId + 2);
        assertEq(ERC721Extended.totalSupply(), 2);

        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri3);
        vm.stopPrank();
        assertEq(ERC721Extended.tokenByIndex(0), tokenId);
        assertEq(ERC721Extended.tokenByIndex(1), tokenId + 2);
        assertEq(ERC721Extended.tokenByIndex(2), tokenId + 3);
        assertEq(ERC721Extended.totalSupply(), 3);
    }

    function testTokenByIndexOutOfBounds() public {
        address owner = makeAddr("owner");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 2);

        vm.expectRevert(bytes("ERC721Enumerable: global index out of bounds"));
        ERC721Extended.tokenByIndex(2);
    }

    function testTokenOfOwnerByIndex() public {
        address owner = makeAddr("owner");
        address other = makeAddr("other");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        string memory uri3 = "my_awesome_nft_uri_3";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        ERC721Extended.safe_mint(owner, uri3);
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 3);
        assertEq(ERC721Extended.tokenOfOwnerByIndex(owner, tokenId), tokenId);

        vm.startPrank(owner);
        ERC721Extended.burn(0);
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 2);
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(owner, tokenId),
            tokenId + 2
        );
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(owner, tokenId + 1),
            tokenId + 1
        );

        vm.startPrank(owner);
        ERC721Extended.safeTransferFrom(owner, other, tokenId + 1, "");
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 2);
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(owner, tokenId),
            tokenId + 2
        );
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(other, tokenId),
            tokenId + 1
        );

        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, "");
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 3);
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(owner, tokenId),
            tokenId + 2
        );
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(owner, tokenId + 1),
            tokenId + 3
        );
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(other, tokenId),
            tokenId + 1
        );
    }

    function testTokenOfOwnerByIndexReverts() public {
        address owner = makeAddr("owner");
        address other = makeAddr("other");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        string memory uri3 = "my_awesome_nft_uri_3";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        ERC721Extended.safe_mint(owner, uri3);
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 3);
        vm.expectRevert(bytes("ERC721Enumerable: owner index out of bounds"));
        ERC721Extended.tokenOfOwnerByIndex(owner, tokenId + 3);

        vm.startPrank(owner);
        ERC721Extended.safeTransferFrom(owner, other, tokenId, "");
        ERC721Extended.safeTransferFrom(owner, other, tokenId + 1, "");
        ERC721Extended.safeTransferFrom(owner, other, tokenId + 2, "");
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), 3);
        vm.expectRevert(bytes("ERC721Enumerable: owner index out of bounds"));
        ERC721Extended.tokenOfOwnerByIndex(owner, tokenId);
        assertEq(ERC721Extended.tokenOfOwnerByIndex(other, tokenId), tokenId);
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(other, tokenId + 1),
            tokenId + 1
        );
        assertEq(
            ERC721Extended.tokenOfOwnerByIndex(other, tokenId + 2),
            tokenId + 2
        );
    }

    function testBurnSuccess() public {
        address owner = makeAddr("owner");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, zeroAddress, tokenId);
        ERC721Extended.burn(tokenId);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.burn(tokenId);
        vm.stopPrank();

        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.ownerOf(tokenId);
        assertEq(ERC721Extended.balanceOf(owner), 1);
    }

    function testBurnSuccessViaApproveAndSetApprovalForAll() public {
        address owner = makeAddr("owner");
        address operator = makeAddr("operator");
        address other = makeAddr("other");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.burn(tokenId + 2);
        ERC721Extended.setApprovalForAll(operator, true);
        ERC721Extended.approve(other, tokenId + 1);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, zeroAddress, tokenId);
        ERC721Extended.burn(tokenId);
        vm.stopPrank();

        vm.startPrank(other);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, zeroAddress, tokenId + 1);
        ERC721Extended.burn(tokenId + 1);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.burn(tokenId);
        vm.stopPrank();

        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.ownerOf(tokenId);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.getApproved(tokenId);
        assertEq(ERC721Extended.balanceOf(owner), 0);
        assertEq(ERC721Extended.balanceOf(operator), 0);
        assertEq(ERC721Extended.balanceOf(other), 0);
    }

    function testSafeMintSuccess() public {
        address owner = makeAddr("owner");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        string memory uri3 = "my_awesome_nft_uri_3";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, false);
        emit Transfer(zeroAddress, owner, tokenId);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(tokenId);
        ERC721Extended.safe_mint(owner, uri1);
        vm.expectEmit(true, true, true, false);
        emit Transfer(zeroAddress, owner, tokenId + 1);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(tokenId + 1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.expectEmit(true, true, true, false);
        emit Transfer(zeroAddress, owner, tokenId + 2);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(tokenId + 2);
        ERC721Extended.safe_mint(owner, uri3);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, zeroAddress, tokenId + 2);
        ERC721Extended.burn(tokenId + 2);
        vm.stopPrank();

        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, false);
        emit Transfer(zeroAddress, owner, tokenId + 3);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(tokenId + 3);
        ERC721Extended.safe_mint(owner, "");
        vm.stopPrank();
        assertEq(ERC721Extended.balanceOf(owner), 3);
        assertEq(ERC721Extended.totalSupply(), 3);
        assertEq(ERC721Extended.ownerOf(tokenId), owner);
        assertEq(ERC721Extended.ownerOf(tokenId + 1), owner);
        assertEq(ERC721Extended.ownerOf(tokenId + 3), owner);
    }

    function testSafeMintTokenAlreadyMinted() public {
        address owner = makeAddr("owner");
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, false);
        emit Transfer(zeroAddress, owner, tokenId);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(tokenId);
        ERC721Extended.safe_mint(owner, uri1);
        vm.expectEmit(true, true, true, false);
        emit Transfer(zeroAddress, owner, tokenId + 1);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(tokenId + 1);
        ERC721Extended.safe_mint(owner, uri2);

        /**
         * @dev To display the default storage layout for a contract
         * in Vyper, use `vyper -f layout yourFileName.vy`.
         */
        vm.store(
            ERC721ExtendedAddr,
            bytes32(uint256(18_446_744_073_709_551_627)),
            bytes32(0)
        );
        vm.expectRevert(bytes("ERC721: token already minted"));
        ERC721Extended.safe_mint(owner, "");
        vm.stopPrank();
    }

    function testSafeMintReceiverContract() public {
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.None
        );
        address owner = address(erc721ReceiverMock);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
        assertEq(ERC721Extended.balanceOf(owner), 1);
        assertEq(ERC721Extended.totalSupply(), 1);
        assertEq(ERC721Extended.ownerOf(tokenId), owner);
    }

    function testSafeMintReceiverContractInvalidReturnIdentifier() public {
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            0x00bb8833,
            ERC721ReceiverMock.Error.None
        );
        address owner = address(erc721ReceiverMock);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        vm.expectRevert(
            bytes("ERC721: transfer to non-ERC721Receiver implementer")
        );
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
    }

    function testSafeMintReceiverContractRevertsWithMessage() public {
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.RevertWithMessage
        );
        address owner = address(erc721ReceiverMock);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        vm.expectRevert(bytes("ERC721ReceiverMock: reverting"));
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
    }

    function testSafeMintReceiverContractRevertsWithoutMessage() public {
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.RevertWithoutMessage
        );
        address owner = address(erc721ReceiverMock);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        vm.expectRevert();
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
    }

    function testSafeMintReceiverContractRevertsWithPanic() public {
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.Panic
        );
        address owner = address(erc721ReceiverMock);
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        vm.expectRevert(stdError.divisionError);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();
    }

    function testSafeMintReceiverContractFunctionNotImplemented() public {
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        vm.expectRevert();
        ERC721Extended.safe_mint(deployer, uri);
        vm.stopPrank();
    }

    function testSafeMintNonMinter() public {
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC721Extended.safe_mint(makeAddr("owner"), "my_awesome_nft_uri");
    }

    function testSafeMintToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("ERC721: mint to the zero address"));
        ERC721Extended.safe_mint(zeroAddress, "my_awesome_nft_uri");
    }

    function testSafeMintOverflow() public {
        /**
         * @dev To display the default storage layout for a contract
         * in Vyper, use `vyper -f layout yourFileName.vy`.
         */
        vm.store(
            ERC721ExtendedAddr,
            bytes32(uint256(18_446_744_073_709_551_627)),
            bytes32(type(uint256).max)
        );
        vm.prank(deployer);
        vm.expectRevert();
        ERC721Extended.safe_mint(makeAddr("owner"), "my_awesome_nft_uri");
    }

    function testSetMinterSuccess() public {
        address owner = deployer;
        address minter = makeAddr("minter");
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
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC721Extended.set_minter(makeAddr("minter"), true);
    }

    function testSetMinterToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("AccessControl: minter is the zero address"));
        ERC721Extended.set_minter(zeroAddress, true);
    }

    function testSetMinterRemoveOwnerAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("AccessControl: minter is owner address"));
        ERC721Extended.set_minter(deployer, false);
    }

    function testPermitSuccess() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
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
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
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
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key + 1,
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
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid + 1,
                ERC721ExtendedAddr
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
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
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        uint256 nonce = 1;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
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
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
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
            key,
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
                ERC721ExtendedAddr
            )
        );
        assertEq(ERC721Extended.DOMAIN_SEPARATOR(), digest);
    }

    function testEIP712Domain() public {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = ERC721Extended.eip712Domain();
        assertEq(fields, hex"0f");
        assertEq(name, _NAME_EIP712);
        assertEq(version, _VERSION_EIP712);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, ERC721ExtendedAddr);
        assertEq(salt, bytes32(0));
        assertEq(extensions, new uint256[](0));

        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
        assertEq(ERC721Extended.DOMAIN_SEPARATOR(), digest);
    }

    function testHasOwner() public {
        assertEq(ERC721Extended.owner(), deployer);
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner, true);
        ERC721Extended.transfer_ownership(newOwner);
        assertEq(ERC721Extended.owner(), newOwner);
        assertTrue(!ERC721Extended.is_minter(oldOwner));
        assertTrue(ERC721Extended.is_minter(newOwner));
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC721Extended.transfer_ownership(makeAddr("newOwner"));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("Ownable: new owner is the zero address"));
        ERC721Extended.transfer_ownership(zeroAddress);
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = zeroAddress;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC721Extended.renounce_ownership();
        assertEq(ERC721Extended.owner(), newOwner);
        assertTrue(!ERC721Extended.is_minter(oldOwner));
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC721Extended.renounce_ownership();
    }

    function testFuzzTransferFrom(
        address owner,
        address approved,
        address operator
    ) public {
        vm.assume(
            owner > address(4_096) &&
                approved > address(4_096) &&
                operator > address(4_096)
        );
        vm.assume(
            owner != approved &&
                owner != operator &&
                owner != zeroAddress &&
                owner.code.length == 0 &&
                owner != makeAddr("receiver")
        );
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
            makeAddr("receiver"),
            false,
            new bytes(0)
        );
    }

    function testFuzzSafeTransferFromWithData(
        address owner,
        address approved,
        address operator,
        bytes memory data
    ) public {
        vm.assume(
            owner > address(4_096) &&
                approved > address(4_096) &&
                operator > address(4_096)
        );
        vm.assume(
            owner != approved &&
                owner != operator &&
                owner != zeroAddress &&
                owner.code.length == 0 &&
                owner != makeAddr("receiver")
        );
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        bytes4 receiverMagicValue = type(IERC721Receiver).interfaceId;
        ERC721ReceiverMock erc721ReceiverMock = new ERC721ReceiverMock(
            receiverMagicValue,
            ERC721ReceiverMock.Error.None
        );
        address receiver = address(erc721ReceiverMock);
        vm.assume(owner != receiver);
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();

        vm.startPrank(owner);
        ERC721Extended.approve(approved, 0);
        ERC721Extended.setApprovalForAll(operator, true);
        vm.stopPrank();

        _shouldTransferTokensByUsers(
            "safeTransferFrom(address,address,uint256)",
            owner,
            approved,
            operator,
            0,
            makeAddr("receiver"),
            false,
            new bytes(0)
        );

        _shouldTransferSafely(
            "safeTransferFrom(address,address,uint256,bytes)",
            owner,
            approved,
            operator,
            0,
            receiver,
            data
        );
    }

    function testFuzzApproveClearingApprovalWithNoPriorApproval(
        address owner,
        address spender
    ) public {
        vm.assume(
            owner != spender && owner != zeroAddress && owner.code.length == 0
        );
        vm.assume(spender > address(4_096));
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

    function testFuzzApproveClearingApprovalWithPriorApproval(
        address owner,
        address spender1
    ) public {
        vm.assume(
            owner != spender1 && owner != zeroAddress && owner.code.length == 0
        );
        vm.assume(spender1 > address(4_096));
        address spender2 = zeroAddress;
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

    function testFuzzApproveWithNoPriorApproval(
        address owner,
        address spender
    ) public {
        vm.assume(
            owner != spender && owner != zeroAddress && owner.code.length == 0
        );
        vm.assume(spender > address(4_096));
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

    function testFuzzApproveWithPriorApproval(
        address owner,
        address spender
    ) public {
        vm.assume(
            owner != spender && owner != zeroAddress && owner.code.length == 0
        );
        vm.assume(spender > address(4_096));
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

    function testFuzzApproveFromNonOwner(address nonOwner) public {
        address owner = makeAddr("owner");
        vm.assume(nonOwner != deployer);
        vm.assume(nonOwner != owner);
        string memory uri = "my_awesome_nft_uri";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        vm.startPrank(nonOwner);
        vm.expectRevert(
            bytes(
                "ERC721: approve caller is not token owner or approved for all"
            )
        );
        ERC721Extended.approve(makeAddr("to"), tokenId);
        vm.stopPrank();
    }

    function testFuzzApproveFromOperatorAddress(
        address owner,
        address operator,
        address spender
    ) public {
        vm.assume(
            owner > address(4_096) &&
                operator > address(4_096) &&
                spender > address(4_096)
        );
        vm.assume(
            owner != operator &&
                owner != spender &&
                owner != zeroAddress &&
                owner.code.length == 0
        );
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

    function testFuzzSetApprovalForAllSuccess(
        address owner,
        address operator
    ) public {
        vm.assume(owner > address(4_096) && operator > address(4_096));
        vm.assume(
            owner != operator && owner != zeroAddress && owner.code.length == 0
        );
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

    function testFuzzGetApprovedApprovedTokenId(
        address owner,
        address spender
    ) public {
        vm.assume(
            owner != spender && owner != zeroAddress && owner.code.length == 0
        );
        vm.assume(spender > address(4_096));
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri);
        vm.stopPrank();

        vm.startPrank(owner);
        ERC721Extended.approve(spender, 0);
        assertEq(ERC721Extended.getApproved(0), spender);
        vm.stopPrank();
    }

    function testFuzzTotalSupply(address owner, string[] calldata uri) public {
        vm.assume(owner != zeroAddress && owner.code.length == 0);
        vm.startPrank(deployer);
        for (uint256 i; i < uri.length; ++i) {
            ERC721Extended.safe_mint(owner, uri[i]);
        }
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), uri.length);
    }

    function testFuzzTokenByIndex(address owner, string[] calldata uri) public {
        vm.assume(owner != zeroAddress && owner.code.length == 0);
        vm.startPrank(deployer);
        for (uint256 i; i < uri.length; ++i) {
            ERC721Extended.safe_mint(owner, uri[i]);
            assertEq(ERC721Extended.tokenByIndex(i), i);
        }
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), uri.length);
    }

    function testFuzzBurnSuccess(address owner) public {
        vm.assume(owner != zeroAddress && owner.code.length == 0);
        string memory uri1 = "my_awesome_nft_uri_1";
        string memory uri2 = "my_awesome_nft_uri_2";
        uint256 tokenId = 0;
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(owner, uri1);
        ERC721Extended.safe_mint(owner, uri2);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Transfer(owner, zeroAddress, tokenId);
        ERC721Extended.burn(tokenId);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.burn(tokenId);
        vm.stopPrank();

        vm.expectRevert(bytes("ERC721: invalid token ID"));
        ERC721Extended.ownerOf(tokenId);
        assertEq(ERC721Extended.balanceOf(owner), 1);
    }

    function testFuzzSafeMintSuccess(address[] calldata owners) public {
        for (uint256 i; i < owners.length; ++i) {
            vm.assume(owners[i] != zeroAddress && owners[i].code.length == 0);
        }
        string memory uri = "my_awesome_nft_uri_1";
        vm.startPrank(deployer);
        for (uint256 i; i < owners.length; ++i) {
            vm.expectEmit(true, true, true, false);
            emit Transfer(zeroAddress, owners[i], i);
            vm.expectEmit(false, false, false, true);
            emit MetadataUpdate(i);
            ERC721Extended.safe_mint(owners[i], uri);
            assertGe(ERC721Extended.balanceOf(owners[i]), 1);
        }
        vm.stopPrank();
        assertEq(ERC721Extended.totalSupply(), owners.length);
    }

    function testFuzzSafeMintNonMinter(address nonOwner) public {
        vm.assume(nonOwner != deployer);
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC721Extended.safe_mint(makeAddr("owner"), "my_awesome_nft_uri");
    }

    function testFuzzSetMinterSuccess(string calldata minter) public {
        address owner = deployer;
        address minterAddr = makeAddr(minter);
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minterAddr, true);
        ERC721Extended.set_minter(minterAddr, true);
        assertTrue(ERC721Extended.is_minter(minterAddr));

        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minterAddr, false);
        ERC721Extended.set_minter(minterAddr, false);
        assertTrue(!ERC721Extended.is_minter(minterAddr));
        vm.stopPrank();
    }

    function testFuzzSetMinterNonOwner(
        address msgSender,
        string calldata minter
    ) public {
        vm.assume(msgSender != deployer);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC721Extended.set_minter(makeAddr(minter), true);
    }

    function testFuzzPermitSuccess(
        string calldata owner,
        string calldata spender,
        uint16 increment
    ) public {
        (address ownerAddr, uint256 key) = makeAddrAndKey(owner);
        address spenderAddr = makeAddr(spender);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(ownerAddr, uri);
        vm.stopPrank();

        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + increment;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spenderAddr,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectEmit(true, true, true, false);
        emit Approval(ownerAddr, spenderAddr, tokenId);
        ERC721Extended.permit(spenderAddr, tokenId, deadline, v, r, s);
        assertEq(ERC721Extended.getApproved(tokenId), spenderAddr);
        assertEq(ERC721Extended.nonces(tokenId), 1);
    }

    function testFuzzPermitInvalid(
        string calldata owner,
        string calldata spender,
        uint16 increment
    ) public {
        vm.assume(
            keccak256(abi.encode(owner)) != keccak256(abi.encode("ownerWrong"))
        );
        (address ownerAddr, ) = makeAddrAndKey(owner);
        (, uint256 keyWrong) = makeAddrAndKey("ownerWrong");
        address spenderAddr = makeAddr(spender);
        uint256 tokenId = 0;
        string memory uri = "my_awesome_nft_uri";
        vm.startPrank(deployer);
        ERC721Extended.safe_mint(ownerAddr, uri);
        vm.stopPrank();

        uint256 nonce = ERC721Extended.nonces(tokenId);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + increment;
        bytes32 domainSeparator = ERC721Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            keyWrong,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            spenderAddr,
                            tokenId,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC721Permit: invalid signature"));
        ERC721Extended.permit(spenderAddr, tokenId, deadline, v, r, s);
    }

    function testFuzzDomainSeparator(uint8 increment) public {
        vm.chainId(block.chainid + increment);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC721ExtendedAddr
            )
        );
        assertEq(ERC721Extended.DOMAIN_SEPARATOR(), digest);
    }

    function testFuzzEIP712Domain(
        bytes1 randomHex,
        uint8 increment,
        bytes32 randomSalt,
        uint256[] calldata randomExtensions
    ) public {
        vm.assume(
            randomHex != hex"0f" &&
                randomSalt != bytes32(0) &&
                randomExtensions.length != 0
        );
        vm.chainId(block.chainid + increment);
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = ERC721Extended.eip712Domain();
        assertTrue(fields != randomHex);
        assertEq(name, _NAME_EIP712);
        assertEq(version, _VERSION_EIP712);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, ERC721ExtendedAddr);
        assertTrue(salt != randomSalt);
        assertTrue(
            keccak256(abi.encode(extensions)) !=
                keccak256(abi.encode(randomExtensions))
        );

        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
        assertEq(ERC721Extended.DOMAIN_SEPARATOR(), digest);
    }

    function testFuzzTransferOwnershipSuccess(
        address newOwner1,
        address newOwner2
    ) public {
        vm.assume(
            newOwner1 != zeroAddress &&
                newOwner1 != deployer &&
                newOwner1 != newOwner2 &&
                newOwner2 != zeroAddress
        );
        address oldOwner = deployer;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner1);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner1, true);
        ERC721Extended.transfer_ownership(newOwner1);
        assertEq(ERC721Extended.owner(), newOwner1);
        assertTrue(!ERC721Extended.is_minter(oldOwner));
        assertTrue(ERC721Extended.is_minter(newOwner1));
        vm.stopPrank();

        vm.startPrank(newOwner1);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner1, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(newOwner1, newOwner2);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner2, true);
        emit OwnershipTransferred(newOwner1, newOwner2);
        ERC721Extended.transfer_ownership(newOwner2);
        assertEq(ERC721Extended.owner(), newOwner2);
        assertTrue(!ERC721Extended.is_minter(newOwner1));
        assertTrue(ERC721Extended.is_minter(newOwner2));
        vm.stopPrank();
    }

    function testFuzzTransferOwnershipNonOwner(
        address nonOwner,
        address newOwner
    ) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC721Extended.transfer_ownership(newOwner);
    }

    function testFuzzRenounceOwnershipSuccess(address newOwner) public {
        vm.assume(newOwner != zeroAddress);
        address oldOwner = deployer;
        address renounceAddress = zeroAddress;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner, true);
        ERC721Extended.transfer_ownership(newOwner);
        vm.stopPrank();

        vm.startPrank(newOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(newOwner, renounceAddress);
        ERC721Extended.renounce_ownership();
        assertEq(ERC721Extended.owner(), renounceAddress);
        vm.stopPrank();
    }

    function testFuzzRenounceOwnershipNonOwner(address nonOwner) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC721Extended.renounce_ownership();
    }
}

contract ERC721Invariants is Test {
    string private constant _NAME = "MyNFT";
    string private constant _SYMBOL = "WAGMI";
    string private constant _BASE_URI = "https://www.wagmi.xyz/";
    string private constant _NAME_EIP712 = "MyNFT";
    string private constant _VERSION_EIP712 = "1";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC721Extended private ERC721Extended;
    ERC721Handler private erc721Handler;

    address private deployer = address(vyperDeployer);

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
        erc721Handler = new ERC721Handler(ERC721Extended, deployer);
        targetContract(address(erc721Handler));
        targetSender(deployer);
    }

    function invariantTotalSupply() public {
        assertEq(ERC721Extended.totalSupply(), erc721Handler.totalSupply());
    }

    function invariantOwner() public {
        assertEq(ERC721Extended.owner(), erc721Handler.owner());
    }
}

contract ERC721Handler {
    address public owner;
    uint256 public totalSupply;
    uint256 private counter;

    IERC721Extended private token;

    address private zeroAddress = address(0);

    constructor(IERC721Extended token_, address owner_) {
        token = token_;
        owner = owner_;
    }

    function safeTransferFrom(
        address ownerAddr,
        address to,
        bytes calldata data
    ) public {
        token.safeTransferFrom(ownerAddr, to, counter, data);
    }

    function safeTransferFrom(address ownerAddr, address to) public {
        token.safeTransferFrom(ownerAddr, to, counter);
    }

    function transferFrom(address ownerAddr, address to) public {
        token.transferFrom(ownerAddr, to, counter);
    }

    function approve(address to) public {
        token.approve(to, counter);
    }

    function setApprovalForAll(address operator, bool approved) public {
        token.setApprovalForAll(operator, approved);
    }

    function permit(
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(spender, counter, deadline, v, r, s);
    }

    function burn() public {
        token.burn(counter);
        counter -= 1;
        totalSupply -= 1;
    }

    function safe_mint(address ownerAddr, string calldata uri) public {
        token.safe_mint(ownerAddr, uri);
        counter += 1;
        totalSupply += 1;
    }

    function set_minter(address minter, bool status) public {
        token.set_minter(minter, status);
    }

    function transfer_ownership(address newOwner) public {
        token.transfer_ownership(newOwner);
        owner = newOwner;
    }

    function renounce_ownership() public {
        token.renounce_ownership();
        owner = zeroAddress;
    }
}
