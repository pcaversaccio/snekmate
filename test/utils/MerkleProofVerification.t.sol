// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IMerkleProofVerification} from "../../test/utils/interfaces/IMerkleProofVerification.sol";

contract MerkleProofVerificationTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IMerkleProofVerification private merkleProofVerification;

    function setUp() public {
        merkleProofVerification = IMerkleProofVerification(
            vyperDeployer.deployContract(
                "src/utils/",
                "MerkleProofVerification"
            )
        );
    }

    function decode() public returns (bytes32[] memory) {
        bytes32[] memory proofDecoded = new bytes32[](7);
        string[] memory cmdsProof = new string[](2);
        cmdsProof[0] = "node";
        cmdsProof[1] = "test/utils/scripts/generate-proof.js";
        bytes memory proof = vm.ffi(cmdsProof);
        (
            bytes32 arg1,
            bytes32 arg2,
            bytes32 arg3,
            bytes32 arg4,
            bytes32 arg5,
            bytes32 arg6,
            bytes32 arg7
        ) = abi.decode(
                proof,
                (bytes32, bytes32, bytes32, bytes32, bytes32, bytes32, bytes32)
            );
        proofDecoded[0] = arg1;
        proofDecoded[1] = arg2;
        proofDecoded[2] = arg3;
        proofDecoded[3] = arg4;
        proofDecoded[4] = arg5;
        proofDecoded[5] = arg6;
        proofDecoded[6] = arg7;

        return proofDecoded;
    }

    function testVerify() public {
        string[] memory cmdsRoot = new string[](2);
        cmdsRoot[0] = "node";
        cmdsRoot[1] = "test/utils/scripts/generate-root.js";
        bytes memory root = vm.ffi(cmdsRoot);

        string[] memory cmdsLeaf = new string[](2);
        cmdsLeaf[0] = "node";
        cmdsLeaf[1] = "test/utils/scripts/generate-leaf.js";
        bytes memory leaf = vm.ffi(cmdsLeaf);

        bytes32[] memory proofDecoded = decode();
        assertTrue(
            merkleProofVerification.verify(
                proofDecoded,
                bytes32(root),
                bytes32(leaf)
            )
        );
    }
}
