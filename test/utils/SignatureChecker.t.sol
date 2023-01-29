// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC1271WalletMock} from "./mocks/ERC1271WalletMock.sol";
import {ERC1271MaliciousMock} from "./mocks/ERC1271MaliciousMock.sol";

import {ISignatureChecker} from "./interfaces/ISignatureChecker.sol";

contract SignatureCheckerTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ISignatureChecker private signatureChecker;
    ERC1271WalletMock private wallet;
    ERC1271MaliciousMock private malicious;

    function setUp() public {
        signatureChecker = ISignatureChecker(
            vyperDeployer.deployContract("src/utils/", "SignatureChecker")
        );
        wallet = new ERC1271WalletMock(vm.addr(1));
        malicious = new ERC1271MaliciousMock();
    }

    function testEOAWithValidSignature() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            signatureChecker.is_valid_signature_now(alice, hash, signature)
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                alice,
                hash,
                signature
            )
        );
    }

    function testEOAWithInvalidSigner() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(alice, hash, signature)
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                alice,
                hash,
                signature
            )
        );
    }

    function testEOAWithInvalidSignature1() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        bytes32 hashWrong = keccak256("WAGMI1");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hashWrong);
        bytes memory signatureInvalid = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                alice,
                hash,
                signatureInvalid
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                alice,
                hash,
                signatureInvalid
            )
        );
    }

    function testEOAWithInvalidSignature2() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signatureInvalid = abi.encodePacked(r, s, bytes1(0xa0));
        vm.expectRevert(bytes("ECDSA: invalid signature"));
        signatureChecker.is_valid_signature_now(alice, hash, signatureInvalid);
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                alice,
                hash,
                signatureInvalid
            )
        );
    }

    function testEOAWithTooHighSValue() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        uint256 sTooHigh = uint256(s) +
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
        bytes memory signatureInvalid = abi.encodePacked(
            r,
            bytes32(sTooHigh),
            v
        );
        vm.expectRevert(bytes("ECDSA: invalid signature 's' value"));
        signatureChecker.is_valid_signature_now(alice, hash, signatureInvalid);
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                alice,
                hash,
                signatureInvalid
            )
        );
    }

    function testEIP1271WithValidSignature() public {
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            signatureChecker.is_valid_signature_now(
                address(wallet),
                hash,
                signature
            )
        );
        assertTrue(
            signatureChecker.is_valid_ERC1271_signature_now(
                address(wallet),
                hash,
                signature
            )
        );
    }

    function testEIP1271WithInvalidSigner() public {
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                address(wallet),
                hash,
                signature
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                address(wallet),
                hash,
                signature
            )
        );
    }

    function testEIP1271WithInvalidSignature1() public {
        bytes32 hash = keccak256("WAGMI");
        bytes32 hashWrong = keccak256("WAGMI1");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hashWrong);
        bytes memory signatureInvalid = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                address(wallet),
                hash,
                signatureInvalid
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                address(wallet),
                hash,
                signatureInvalid
            )
        );
    }

    function testEIP1271WithInvalidSignature2() public {
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signatureInvalid = abi.encodePacked(r, s, bytes1(0xa0));
        vm.expectRevert(bytes("ECDSA: invalid signature"));
        signatureChecker.is_valid_signature_now(
            address(wallet),
            hash,
            signatureInvalid
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                address(wallet),
                hash,
                signatureInvalid
            )
        );
    }

    function testEIP1271WithMaliciousWallet() public {
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                address(malicious),
                hash,
                signature
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                address(malicious),
                hash,
                signature
            )
        );
    }

    function testEIP1271NoIsValidSignatureFunction() public {
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                address(vyperDeployer),
                hash,
                signature
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                address(vyperDeployer),
                hash,
                signature
            )
        );
    }
}
