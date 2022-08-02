// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/Test.sol";
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
        assertEq(alice, ECDSA._recover_sig(hash, signature));
    }

    function testRecoverWithShortSignature() public {
        bytes32 hash = keccak256("WAGMI");
        bytes memory signature = abi.encodePacked("0x0123456789");
        assertEq(address(0), ECDSA._recover_sig(hash, signature));
    }

    function testRecoverWithLongSignature() public {
        bytes32 hash = keccak256("WAGMI");
        bytes memory signature = abi.encodePacked(
            "0x012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        );
        vm.expectRevert();
        ECDSA._recover_sig(hash, signature);
    }

    function testRecoverWithArbitraryMessage() public {
        address alice = vm.addr(1);
        bytes32 hash = bytes32("0x5741474d49");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(alice, ECDSA._recover_sig(hash, signature));
    }

    function testRecoverWithWrongMessage() public {
        address alice = vm.addr(1);
        bytes32 hashCorrect = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hashCorrect);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes32 hashWrong = keccak256("WAGMI1");
        address recoveredAddress = ECDSA._recover_sig(hashWrong, signature);
        assertTrue(alice != recoveredAddress);
    }

    function testRecoverWithInvalidSignature() public {
        bytes32 hash = keccak256("WAGMI");
        bytes memory signatureInvalid = abi.encodePacked(
            "0x332ce75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e01c"
        );
        vm.expectRevert();
        ECDSA._recover_sig(hash, signatureInvalid);
    }
}
