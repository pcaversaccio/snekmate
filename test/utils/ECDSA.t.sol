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

    function setUp() public {
        ECDSA = IECDSA(vyperDeployer.deployContract("src/utils/", "ECDSA"));
    }

    function testRecoverWithValidSignature() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(alice, ECDSA.recover_sig(hash, signature));
    }

    function testRecoverWithTooShortSignature() public {
        bytes32 hash = keccak256("WAGMI");
        bytes memory signature = abi.encodePacked("0x0123456789");
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
        bytes memory signatureInvalid = abi.encodePacked(
            "0x98f089cabeb2f7b29052b41de3f863deae900c39e35f044039733c8ee9e2fb0860233dd93c5bdd0ceb03b9ae4fd8ef2ab02026399626ee49da226ca7adbb804a1c"
        );
        vm.expectRevert();
        ECDSA.recover_sig(hash, signatureInvalid);
    }

    function testEthSignedMessageHash() public {
        bytes32 hash = keccak256("WAGMI");
        bytes32 digest1 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        bytes32 digest2 = ECDSA.to_eth_signed_message_hash(hash);
        assertEq(digest1, digest2);
    }

    function testToTypedDataHash() public {
        bytes32 domainSeparator = keccak256("WAGMI");
        bytes32 structHash = keccak256("GM");
        bytes32 digest1 = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        bytes32 digest2 = ECDSA.to_typed_data_hash(domainSeparator, structHash);
        assertEq(digest1, digest2);
    }
}
