// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.16;

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

    function decode(bool flag)
        internal
        returns (bytes32[] memory, bytes32[] memory)
    {
        bytes32[] memory proofDecoded = new bytes32[](7);
        bytes32[] memory proofDecodedSliced = new bytes32[](6);

        if (flag) {
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
                    (
                        bytes32,
                        bytes32,
                        bytes32,
                        bytes32,
                        bytes32,
                        bytes32,
                        bytes32
                    )
                );
            proofDecoded[0] = arg1;
            proofDecoded[1] = arg2;
            proofDecoded[2] = arg3;
            proofDecoded[3] = arg4;
            proofDecoded[4] = arg5;
            proofDecoded[5] = arg6;
            proofDecoded[6] = arg7;

            proofDecodedSliced[0] = arg2;
            proofDecodedSliced[1] = arg3;
            proofDecodedSliced[2] = arg4;
            proofDecodedSliced[3] = arg5;
            proofDecodedSliced[4] = arg6;
            proofDecodedSliced[5] = arg7;

            return (proofDecoded, proofDecodedSliced);
        } else {
            string[] memory cmdsProof = new string[](2);
            cmdsProof[0] = "node";
            cmdsProof[1] = "test/utils/scripts/generate-bad-proof.js";
            bytes memory proof = vm.ffi(cmdsProof);
            bytes32 arg1 = abi.decode(proof, (bytes32));
            proofDecoded[0] = arg1;

            return (proofDecoded, proofDecodedSliced);
        }
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

        string[] memory cmdsNoSuchLeaf = new string[](2);
        cmdsNoSuchLeaf[0] = "node";
        cmdsNoSuchLeaf[1] = "test/utils/scripts/generate-no-such-leaf.js";
        bytes memory noSuchLeaf = vm.ffi(cmdsNoSuchLeaf);

        (
            bytes32[] memory proofDecoded,
            bytes32[] memory proofDecodedSliced
        ) = decode(true);

        assertTrue(
            merkleProofVerification.verify(
                proofDecoded,
                bytes32(root),
                bytes32(leaf)
            )
        );
        assertTrue(
            merkleProofVerification.verify(
                proofDecodedSliced,
                bytes32(root),
                bytes32(noSuchLeaf)
            )
        );
    }

    function testInvalidMerkleProof() public {
        string[] memory cmdsCorrectRoot = new string[](2);
        cmdsCorrectRoot[0] = "node";
        cmdsCorrectRoot[1] = "test/utils/scripts/generate-root.js";
        bytes memory root = vm.ffi(cmdsCorrectRoot);

        string[] memory cmdsCorrectLeaf = new string[](2);
        cmdsCorrectLeaf[0] = "node";
        cmdsCorrectLeaf[1] = "test/utils/scripts/generate-leaf.js";
        bytes memory leaf = vm.ffi(cmdsCorrectLeaf);

        (bytes32[] memory badProofDecoded, ) = decode(false);

        assertTrue(
            !merkleProofVerification.verify(
                badProofDecoded,
                bytes32(root),
                bytes32(leaf)
            )
        );
    }

    function testInvalidMerkleProofLength() public {
        string[] memory cmdsRoot = new string[](2);
        cmdsRoot[0] = "node";
        cmdsRoot[1] = "test/utils/scripts/generate-root.js";
        bytes memory root = vm.ffi(cmdsRoot);

        string[] memory cmdsLeaf = new string[](2);
        cmdsLeaf[0] = "node";
        cmdsLeaf[1] = "test/utils/scripts/generate-leaf.js";
        bytes memory leaf = vm.ffi(cmdsLeaf);

        (bytes32[] memory proofDecoded, ) = decode(true);

        bytes32[] memory proofInvalidLengthDecoded = new bytes32[](3);
        proofInvalidLengthDecoded[0] = proofDecoded[0];
        proofInvalidLengthDecoded[1] = proofDecoded[1];
        proofInvalidLengthDecoded[2] = proofDecoded[2];

        assertTrue(
            !merkleProofVerification.verify(
                proofInvalidLengthDecoded,
                bytes32(root),
                bytes32(leaf)
            )
        );
    }
}
