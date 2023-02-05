// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";

import {IECDSA} from "./interfaces/IECDSA.sol";

/**
 * @dev Error that occurs when the signature length is invalid.
 * @param emitter The contract that emits the error.
 */
error InvalidSignatureLength(address emitter);

/**
 * @dev Error that occurs when the signature value 's' is invalid.
 * @param emitter The contract that emits the error.
 */
error InvalidSignatureSValue(address emitter);

contract ECDSATest is Test {
    using BytesLib for bytes;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IECDSA private ECDSA;

    /**
     * @dev Transforms a standard signature into an EIP-2098
     * compliant signature.
     * @param signature The secp256k1 64/65-bytes signature.
     * @return short The 64-bytes EIP-2098 compliant signature.
     */
    function to2098Format(
        bytes memory signature
    ) internal view returns (bytes memory) {
        if (signature.length != 65)
            revert InvalidSignatureLength(address(this));
        if (uint8(signature[32]) >> 7 == 1)
            revert InvalidSignatureSValue(address(this));
        bytes memory short = signature.slice(0, 64);
        uint8 parityBit = uint8(short[32]) | ((uint8(signature[64]) % 27) << 7);
        short[32] = bytes1(parityBit);
        return short;
    }

    function setUp() public {
        ECDSA = IECDSA(vyperDeployer.deployContract("src/utils/", "ECDSA"));
    }

    function testRecoverWithValidSignature() public {
        /// @dev Standard signature check.
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(alice, ECDSA.recover_sig(hash, signature));

        /// @dev EIP-2098 signature check.
        bytes memory signature2098 = to2098Format(signature);
        assertEq(alice, ECDSA.recover_sig(hash, signature2098));
    }

    function testRecoverWithTooShortSignature() public {
        /// @dev Standard signature check.
        bytes32 hash = keccak256("WAGMI");
        bytes memory signature = "0x0123456789";
        assertEq(address(0), ECDSA.recover_sig(hash, signature));

        /// @dev EIP-2098 signature check.
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidSignatureLength.selector,
                address(this)
            )
        );
        to2098Format(signature);
    }

    function testRecoverWithTooLongSignature() public {
        /// @dev Standard signature check.
        bytes32 hash = keccak256("WAGMI");
        bytes memory signature = bytes(
            "0x012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        );
        vm.expectRevert();
        ECDSA.recover_sig(hash, signature);

        /// @dev EIP-2098 signature check.
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidSignatureLength.selector,
                address(this)
            )
        );
        to2098Format(signature);
    }

    function testRecoverWithArbitraryMessage() public {
        /// @dev Standard signature check.
        address alice = vm.addr(1);
        bytes32 hash = bytes32("0x5741474d49");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(alice, ECDSA.recover_sig(hash, signature));

        /// @dev EIP-2098 signature check.
        bytes memory signature2098 = to2098Format(signature);
        assertEq(alice, ECDSA.recover_sig(hash, signature2098));
    }

    function testRecoverWithWrongMessage() public {
        /// @dev Standard signature check.
        address alice = vm.addr(1);
        bytes32 hashCorrect = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hashCorrect);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes32 hashWrong = keccak256("WAGMI1");
        address recoveredAddress = ECDSA.recover_sig(hashWrong, signature);
        assertTrue(alice != recoveredAddress);

        /// @dev EIP-2098 signature check.
        bytes memory signature2098 = to2098Format(signature);
        assertTrue(alice != ECDSA.recover_sig(hashWrong, signature2098));
    }

    function testRecoverWithInvalidSignature() public {
        /// @dev Standard signature check.
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signatureInvalid = abi.encodePacked(r, s, bytes1(0xa0));
        vm.expectRevert(bytes("ECDSA: invalid signature"));
        ECDSA.recover_sig(hash, signatureInvalid);
    }

    function testRecoverWith0x00Value() public {
        /// @dev Standard signature check.
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signatureWithoutVersion = abi.encodePacked(r, s);
        bytes1 version = 0x00;
        vm.expectRevert(bytes("ECDSA: invalid signature"));
        ECDSA.recover_sig(
            hash,
            abi.encodePacked(signatureWithoutVersion, version)
        );
    }

    function testRecoverWithWrongVersion() public {
        /// @dev Standard signature check.
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signatureWithoutVersion = abi.encodePacked(r, s);
        bytes1 version = 0x02;
        vm.expectRevert(bytes("ECDSA: invalid signature"));
        ECDSA.recover_sig(
            hash,
            abi.encodePacked(signatureWithoutVersion, version)
        );
    }

    function testRecoverWithCorrectVersion() public {
        /// @dev Standard signature check.
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signatureWithoutVersion = abi.encodePacked(r, s);
        assertEq(
            alice,
            ECDSA.recover_sig(
                hash,
                abi.encodePacked(signatureWithoutVersion, v)
            )
        );

        /// @dev EIP-2098 signature check.
        bytes memory signature2098 = to2098Format(
            abi.encodePacked(signatureWithoutVersion, v)
        );
        assertEq(alice, ECDSA.recover_sig(hash, signature2098));
    }

    function testRecoverWithTooHighSValue() public {
        /// @dev Standard signature check.
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        uint256 sTooHigh = uint256(s) +
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
        bytes memory signature = abi.encodePacked(r, bytes32(sTooHigh), v);
        vm.expectRevert(bytes("ECDSA: invalid signature 's' value"));
        ECDSA.recover_sig(hash, signature);

        /// @dev EIP-2098 signature check.
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidSignatureSValue.selector,
                address(this)
            )
        );
        to2098Format(signature);
    }

    function testEthSignedMessageHash() public {
        bytes32 hash = keccak256("WAGMI");
        bytes32 digest1 = ECDSA.to_eth_signed_message_hash(hash);
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        assertEq(digest1, digest2);
    }

    function testToTypedDataHash() public {
        bytes32 domainSeparator = keccak256("WAGMI");
        bytes32 structHash = keccak256("GM");
        bytes32 digest1 = ECDSA.to_typed_data_hash(domainSeparator, structHash);
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        assertEq(digest1, digest2);
    }
}
