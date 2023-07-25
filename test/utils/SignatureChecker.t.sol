// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC1271WalletMock} from "./mocks/ERC1271WalletMock.sol";
import {ERC1271MaliciousMock} from "./mocks/ERC1271MaliciousMock.sol";

import {ISignatureChecker} from "./interfaces/ISignatureChecker.sol";

contract SignatureCheckerTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    ERC1271WalletMock private wallet = new ERC1271WalletMock(makeAddr("alice"));
    ERC1271MaliciousMock private malicious = new ERC1271MaliciousMock();

    ISignatureChecker private signatureChecker;

    address private deployer = address(vyperDeployer);
    address private walletAddr = address(wallet);
    address private maliciousAddr = address(malicious);

    function setUp() public {
        signatureChecker = ISignatureChecker(
            vyperDeployer.deployContract("src/utils/", "SignatureChecker")
        );
    }

    function testEOAWithValidSignature() public {
        (address alice, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
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
        (address alice, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key + 1, hash);
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
        (address alice, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        bytes32 hashWrong = keccak256("WAGMI1");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hashWrong);
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
        (address alice, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(key, hash);
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
        (address alice, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        uint256 sTooHigh = uint256(s) +
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
        bytes memory signatureInvalid = abi.encodePacked(
            r,
            bytes32(sTooHigh),
            v
        );
        vm.expectRevert(bytes("ECDSA: invalid signature `s` value"));
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
        (, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            signatureChecker.is_valid_signature_now(walletAddr, hash, signature)
        );
        assertTrue(
            signatureChecker.is_valid_ERC1271_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
    }

    function testEIP1271WithInvalidSigner() public {
        (, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key + 1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
    }

    function testEIP1271WithInvalidSignature1() public {
        (, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        bytes32 hashWrong = keccak256("WAGMI1");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hashWrong);
        bytes memory signatureInvalid = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                walletAddr,
                hash,
                signatureInvalid
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                walletAddr,
                hash,
                signatureInvalid
            )
        );
    }

    function testEIP1271WithInvalidSignature2() public {
        (, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(key, hash);
        bytes memory signatureInvalid = abi.encodePacked(r, s, bytes1(0xa0));
        vm.expectRevert(bytes("ECDSA: invalid signature"));
        signatureChecker.is_valid_signature_now(
            walletAddr,
            hash,
            signatureInvalid
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                walletAddr,
                hash,
                signatureInvalid
            )
        );
    }

    function testEIP1271WithMaliciousWallet() public {
        (, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                maliciousAddr,
                hash,
                signature
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                maliciousAddr,
                hash,
                signature
            )
        );
    }

    function testEIP1271NoIsValidSignatureFunction() public {
        (, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(deployer, hash, signature)
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                deployer,
                hash,
                signature
            )
        );
    }

    function testFuzzEOAWithValidSignature(
        string calldata signer,
        string calldata message
    ) public {
        (address alice, uint256 key) = makeAddrAndKey(signer);
        bytes32 hash = keccak256(abi.encode(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
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

    function testFuzzEOAWithInvalidSigner(
        string calldata signer,
        string calldata message
    ) public {
        (address alice, uint256 key) = makeAddrAndKey(signer);
        bytes32 hash = keccak256(abi.encode(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key + 1, hash);
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

    function testFuzzEOAWithInvalidSignature(
        bytes calldata signature,
        string calldata message
    ) public {
        vm.assume(signature.length < 64);
        address alice = makeAddr("alice");
        bytes32 hash = keccak256(abi.encode(message));
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

    function testFuzzEIP1271WithValidSignature(string calldata message) public {
        (, uint256 key) = makeAddrAndKey("alice");
        bytes32 hash = keccak256(abi.encode(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            signatureChecker.is_valid_signature_now(walletAddr, hash, signature)
        );
        assertTrue(
            signatureChecker.is_valid_ERC1271_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
    }

    function testFuzzEIP1271WithInvalidSigner(
        string calldata signer,
        string calldata message
    ) public {
        vm.assume(
            keccak256(abi.encode(signer)) != keccak256(abi.encode("alice"))
        );
        (, uint256 key) = makeAddrAndKey(signer);
        bytes32 hash = keccak256(abi.encode(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
    }

    function testEIP1271WithInvalidSignature(
        bytes calldata signature,
        string calldata message
    ) public {
        vm.assume(signature.length < 64);
        bytes32 hash = keccak256(abi.encode(message));
        assertTrue(
            !signatureChecker.is_valid_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
        assertTrue(
            !signatureChecker.is_valid_ERC1271_signature_now(
                walletAddr,
                hash,
                signature
            )
        );
    }
}
