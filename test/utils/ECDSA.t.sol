// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IECDSA} from "../../test/utils/IECDSA.sol";

contract ECDSATest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    // solhint-disable-next-line var-name-mixedcase
    IECDSA private ECDSA;

    function to2098Format(bytes calldata signature)
        public
        pure
        returns (bytes memory)
    {
        require(signature.length == 65, "invalid signature length");
        require(uint8(signature[32]) >> 7 != 1, "invalid signature 's' value");
        bytes memory short = signature[0:32];
        uint8 parityBit = uint8(short[32]) | ((uint8(signature[64]) % 27) << 7);
        short[32] = bytes1(parityBit);
        return short;
    }

    function setUp() public {
        ECDSA = IECDSA(vyperDeployer.deployContract("src/utils/", "ECDSA"));
    }

    function testRecoverWithValidSignature() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(alice, ECDSA.recover_sig(hash, signature));

        // EIP-2098
        // console.logBytes1(signature[32]);
        // bytes memory signature2098 = to2098Format(signature);
        // assertEq(alice, ECDSA.recover_sig(hash, signature2098));
    }

    function testRecoverWithTooShortSignature() public {
        bytes32 hash = keccak256("WAGMI");
        bytes memory signature = "0x0123456789";
        assertEq(address(0), ECDSA.recover_sig(hash, signature));
    }

    function testRecoverWithTooLongSignature() public {
        bytes32 hash = keccak256("WAGMI");
        bytes memory signature = abi.encodePacked(
            "0x012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        );
        vm.expectRevert();
        ECDSA.recover_sig(hash, signature);
    }

    function testRecoverWithArbitraryMessage() public {
        address alice = vm.addr(1);
        bytes32 hash = bytes32("0x5741474d49");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(alice, ECDSA.recover_sig(hash, signature));
    }

    function testRecoverWithWrongMessage() public {
        address alice = vm.addr(1);
        bytes32 hashCorrect = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hashCorrect);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes32 hashWrong = keccak256("WAGMI1");
        address recoveredAddress = ECDSA.recover_sig(hashWrong, signature);
        assertTrue(alice != recoveredAddress);
    }

    function testRecoverWithInvalidSignature() public {
        bytes32 hash = keccak256("WAGMI");
        (, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signatureInvalid = abi.encodePacked(r, s, bytes1(0xa0));
        vm.expectRevert(bytes("ECDSA: invalid signature"));
        ECDSA.recover_sig(hash, signatureInvalid);
    }

    function testRecoverWith00Value() public {
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
    }

    function testRecoverWithTooHighSValue() public {
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        uint256 sTooHigh = uint256(s) +
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
        bytes memory signature = abi.encodePacked(r, bytes32(sTooHigh), v);
        vm.expectRevert(bytes("ECDSA: invalid signature 's' value"));
        ECDSA.recover_sig(hash, signature);
    }

    function testEthSignedMessageHash() public {
        bytes32 hash = keccak256("WAGMI");
        bytes32 digest1 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        bytes32 digest2 = ECDSA.to_eth_signed_message_hash(hash);
        assertEq(digest1, digest2);
    }

    function testToTypedDataHash() public {
        bytes32 domainSeparator = keccak256("WAGMI");
        bytes32 structHash = keccak256("GM");
        bytes32 digest1 = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        bytes32 digest2 = ECDSA.to_typed_data_hash(domainSeparator, structHash);
        assertEq(digest1, digest2);
    }
}
