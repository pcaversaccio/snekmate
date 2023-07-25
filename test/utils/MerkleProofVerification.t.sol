// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {Merkle} from "murky/Merkle.sol";

import {IMerkleProofVerification} from "./interfaces/IMerkleProofVerification.sol";

contract MerkleProofVerificationTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    Merkle private merkleGenerator = new Merkle();

    IMerkleProofVerification private merkleProofVerification;

    /**
     * @dev An `internal` helper function that converts the JavaScript-based
     * proof after calling the foreign function interface (ffi) cheatcode
     * `vm.ffi` into a Solidity-compatible 32-byte array type.
     * @return bytes32[] The 32-byte array containing sibling hashes
     * on the branch from the `leaf` to the `root` of the Merkle tree.
     */
    function decodeCorrectProofPayload() internal returns (bytes32[] memory) {
        bytes32[] memory proofDecoded = new bytes32[](6);
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
            bytes32 arg6
        ) = abi.decode(
                proof,
                (bytes32, bytes32, bytes32, bytes32, bytes32, bytes32)
            );
        proofDecoded[0] = arg1;
        proofDecoded[1] = arg2;
        proofDecoded[2] = arg3;
        proofDecoded[3] = arg4;
        proofDecoded[4] = arg5;
        proofDecoded[5] = arg6;
        return proofDecoded;
    }

    /**
     * @dev An `internal` helper function that converts the JavaScript-based
     * multiproof after calling the foreign function interface (ffi) cheatcode
     * `vm.ffi` into a Solidity-compatible 32-byte array type.
     * @return bytes32[] The 32-byte array containing sibling hashes
     * on the branches from `leaves` to the `root` of the Merkle tree.
     */
    function decodeCorrectMultiProofPayload()
        internal
        returns (bytes32[] memory)
    {
        bytes32[] memory multiProofDecoded = new bytes32[](8);
        string[] memory cmdsMultiProof = new string[](2);
        cmdsMultiProof[0] = "node";
        cmdsMultiProof[1] = "test/utils/scripts/generate-multiproof.js";
        bytes memory multiProof = vm.ffi(cmdsMultiProof);
        (
            bytes32 arg1,
            bytes32 arg2,
            bytes32 arg3,
            bytes32 arg4,
            bytes32 arg5,
            bytes32 arg6,
            bytes32 arg7,
            bytes32 arg8
        ) = abi.decode(
                multiProof,
                (
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32
                )
            );
        multiProofDecoded[0] = arg1;
        multiProofDecoded[1] = arg2;
        multiProofDecoded[2] = arg3;
        multiProofDecoded[3] = arg4;
        multiProofDecoded[4] = arg5;
        multiProofDecoded[5] = arg6;
        multiProofDecoded[6] = arg7;
        multiProofDecoded[7] = arg8;
        return multiProofDecoded;
    }

    /**
     * @dev An `internal` helper function that converts the JavaScript-based
     * proof flags after calling the foreign function interface (ffi) cheatcode
     * `vm.ffi` into a Solidity-compatible Boolean array type.
     * @return bool[] The Boolean array of flags indicating whether another
     * value from the "main queue" (merging branches) or an element from the
     * `proof` array is used to calculate the next hash.
     */
    function decodeCorrectMultiProofProofFlags()
        internal
        returns (bool[] memory)
    {
        bool[] memory multiProofProofFlagsDecoded = new bool[](10);
        string[] memory cmdsMultiProofProofFlags = new string[](2);
        cmdsMultiProofProofFlags[0] = "node";
        cmdsMultiProofProofFlags[
            1
        ] = "test/utils/scripts/generate-multiproof-proof-flags.js";
        bytes memory multiProofProofFlags = vm.ffi(cmdsMultiProofProofFlags);
        (
            bool arg1,
            bool arg2,
            bool arg3,
            bool arg4,
            bool arg5,
            bool arg6,
            bool arg7,
            bool arg8,
            bool arg9,
            bool arg10
        ) = abi.decode(
                multiProofProofFlags,
                (bool, bool, bool, bool, bool, bool, bool, bool, bool, bool)
            );
        multiProofProofFlagsDecoded[0] = arg1;
        multiProofProofFlagsDecoded[1] = arg2;
        multiProofProofFlagsDecoded[2] = arg3;
        multiProofProofFlagsDecoded[3] = arg4;
        multiProofProofFlagsDecoded[4] = arg5;
        multiProofProofFlagsDecoded[5] = arg6;
        multiProofProofFlagsDecoded[6] = arg7;
        multiProofProofFlagsDecoded[7] = arg8;
        multiProofProofFlagsDecoded[8] = arg9;
        multiProofProofFlagsDecoded[9] = arg10;
        return multiProofProofFlagsDecoded;
    }

    /**
     * @dev An `internal` helper function that converts the JavaScript-based
     * proof after calling the foreign function interface (ffi) cheatcode
     * `vm.ffi` into a Solidity-compatible 32-byte array type.
     * @notice This `internal` helper function is used to demonstrate that it
     * is also possible to create valid proofs for certain 64-byte values that
     * are *not* contained in `elements` (https://github.com/pcaversaccio/snekmate/blob/main/test/utils/scripts/elements.js).
     * @return bytes32[] The 32-byte array containing sibling hashes
     * on the branch from the `leaf` to the `root` of the Merkle tree.
     */
    function decodeNoSuchLeafProofPayload()
        internal
        returns (bytes32[] memory)
    {
        bytes32[] memory proofDecodedSliced = new bytes32[](6);
        string[] memory cmdsProof = new string[](2);
        cmdsProof[0] = "node";
        cmdsProof[1] = "test/utils/scripts/generate-proof-no-such-leaf.js";
        bytes memory proof = vm.ffi(cmdsProof);
        (
            ,
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
        proofDecodedSliced[0] = arg2;
        proofDecodedSliced[1] = arg3;
        proofDecodedSliced[2] = arg4;
        proofDecodedSliced[3] = arg5;
        proofDecodedSliced[4] = arg6;
        proofDecodedSliced[5] = arg7;
        return proofDecodedSliced;
    }

    /**
     * @dev An `internal` helper function that converts the JavaScript-based
     * proof after calling the foreign function interface (ffi) cheatcode
     * `vm.ffi` into a Solidity-compatible 32-byte array type.
     * @notice This `internal` helper function is used to decode a bad proof.
     * @return bytes32[] The 32-byte array containing sibling hashes
     * on the branch from the `leaf` to the `root` of the Merkle tree.
     */
    function decodeBadProofPayload() internal returns (bytes32[] memory) {
        bytes32[] memory proofDecoded = new bytes32[](1);
        string[] memory cmdsProof = new string[](2);
        cmdsProof[0] = "node";
        cmdsProof[1] = "test/utils/scripts/generate-bad-proof.js";
        bytes memory proof = vm.ffi(cmdsProof);
        bytes32 arg = abi.decode(proof, (bytes32));
        proofDecoded[0] = arg;
        return proofDecoded;
    }

    /**
     * @dev An `internal` helper function that converts the JavaScript-based
     * multiproof after calling the foreign function interface (ffi) cheatcode
     * `vm.ffi` into a Solidity-compatible 32-byte array type.
     * @notice This `internal` helper function is used to decode a bad multiproof.
     * @return bytes32[] The 32-byte array containing sibling hashes
     * on the branches from `leaves` to the `root` of the Merkle tree.
     */
    function decodeBadMultiProofPayload() internal returns (bytes32[] memory) {
        bytes32[] memory multiProofDecoded = new bytes32[](5);
        string[] memory cmdsMultiProof = new string[](2);
        cmdsMultiProof[0] = "node";
        cmdsMultiProof[1] = "test/utils/scripts/generate-bad-multiproof.js";
        bytes memory multiProof = vm.ffi(cmdsMultiProof);
        (
            bytes32 arg1,
            bytes32 arg2,
            bytes32 arg3,
            bytes32 arg4,
            bytes32 arg5
        ) = abi.decode(
                multiProof,
                (bytes32, bytes32, bytes32, bytes32, bytes32)
            );
        multiProofDecoded[0] = arg1;
        multiProofDecoded[1] = arg2;
        multiProofDecoded[2] = arg3;
        multiProofDecoded[3] = arg4;
        multiProofDecoded[4] = arg5;
        return multiProofDecoded;
    }

    /**
     * @dev An `internal` helper function that converts the JavaScript-based
     * proof flags after calling the foreign function interface (ffi) cheatcode
     * `vm.ffi` into a Solidity-compatible Boolean array type.
     * @notice This `internal` helper function is used to decode a bad multiproof
     * proof flags array.
     * @return bool[] The Boolean array of flags indicating whether another
     * value from the "main queue" (merging branches) or an element from the
     * `proof` array is used to calculate the next hash.
     */
    function decodeBadMultiProofProofFlags() internal returns (bool[] memory) {
        bool[] memory multiProofProofFlagsDecoded = new bool[](7);
        string[] memory cmdsMultiProofProofFlags = new string[](2);
        cmdsMultiProofProofFlags[0] = "node";
        cmdsMultiProofProofFlags[
            1
        ] = "test/utils/scripts/generate-bad-multiproof-proof-flags.js";
        bytes memory multiProofProofFlags = vm.ffi(cmdsMultiProofProofFlags);
        (
            bool arg1,
            bool arg2,
            bool arg3,
            bool arg4,
            bool arg5,
            bool arg6,
            bool arg7
        ) = abi.decode(
                multiProofProofFlags,
                (bool, bool, bool, bool, bool, bool, bool)
            );
        multiProofProofFlagsDecoded[0] = arg1;
        multiProofProofFlagsDecoded[1] = arg2;
        multiProofProofFlagsDecoded[2] = arg3;
        multiProofProofFlagsDecoded[3] = arg4;
        multiProofProofFlagsDecoded[4] = arg5;
        multiProofProofFlagsDecoded[5] = arg6;
        multiProofProofFlagsDecoded[6] = arg7;
        return multiProofProofFlagsDecoded;
    }

    function setUp() public {
        merkleProofVerification = IMerkleProofVerification(
            vyperDeployer.deployContract(
                "src/utils/",
                "MerkleProofVerification"
            )
        );
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

        bytes32[] memory proofDecoded = decodeCorrectProofPayload();

        assertTrue(
            merkleProofVerification.verify(
                proofDecoded,
                bytes32(root),
                bytes32(leaf)
            )
        );

        string[] memory cmdsRootNoSuchLeaf = new string[](2);
        cmdsRootNoSuchLeaf[0] = "node";
        cmdsRootNoSuchLeaf[
            1
        ] = "test/utils/scripts/generate-root-no-such-leaf.js";
        bytes memory rootNoSuchLeaf = vm.ffi(cmdsRootNoSuchLeaf);

        string[] memory cmdsNoSuchLeaf = new string[](2);
        cmdsNoSuchLeaf[0] = "node";
        cmdsNoSuchLeaf[1] = "test/utils/scripts/generate-no-such-leaf.js";
        bytes memory noSuchLeaf = vm.ffi(cmdsNoSuchLeaf);

        bytes32[] memory proofDecodedSliced = decodeNoSuchLeafProofPayload();

        assertTrue(
            merkleProofVerification.verify(
                proofDecodedSliced,
                bytes32(rootNoSuchLeaf),
                bytes32(noSuchLeaf)
            )
        );
    }

    function testInvalidMerkleProof() public {
        string[] memory cmdsCorrectRoot = new string[](2);
        cmdsCorrectRoot[0] = "node";
        cmdsCorrectRoot[1] = "test/utils/scripts/generate-root.js";
        bytes memory correctRoot = vm.ffi(cmdsCorrectRoot);

        string[] memory cmdsCorrectLeaf = new string[](2);
        cmdsCorrectLeaf[0] = "node";
        cmdsCorrectLeaf[1] = "test/utils/scripts/generate-leaf.js";
        bytes memory leaf = vm.ffi(cmdsCorrectLeaf);

        bytes32[] memory badProofDecoded = decodeBadProofPayload();

        assertTrue(
            !merkleProofVerification.verify(
                badProofDecoded,
                bytes32(correctRoot),
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

        bytes32[] memory proofDecoded = decodeCorrectProofPayload();

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

    function testMultiProofVerify() public {
        string[] memory cmdsRoot = new string[](2);
        cmdsRoot[0] = "node";
        cmdsRoot[1] = "test/utils/scripts/generate-root.js";
        bytes memory root = vm.ffi(cmdsRoot);

        string[] memory cmdsLeaves = new string[](2);
        cmdsLeaves[0] = "node";
        cmdsLeaves[1] = "test/utils/scripts/generate-multiproof-leaves.js";
        bytes memory leaves = vm.ffi(cmdsLeaves);
        bytes32[] memory leavesDecoded = new bytes32[](3);
        (bytes32 arg1, bytes32 arg2, bytes32 arg3) = abi.decode(
            leaves,
            (bytes32, bytes32, bytes32)
        );
        leavesDecoded[0] = arg1;
        leavesDecoded[1] = arg2;
        leavesDecoded[2] = arg3;

        bool[] memory proofFlags = decodeCorrectMultiProofProofFlags();
        bytes32[] memory multiProofDecoded = decodeCorrectMultiProofPayload();

        assertTrue(
            merkleProofVerification.multi_proof_verify(
                multiProofDecoded,
                proofFlags,
                bytes32(root),
                leavesDecoded
            )
        );
    }

    function testInvalidMerkleMultiProof() public {
        string[] memory cmdsCorrectRoot = new string[](2);
        cmdsCorrectRoot[0] = "node";
        cmdsCorrectRoot[1] = "test/utils/scripts/generate-root.js";
        bytes memory correctRoot = vm.ffi(cmdsCorrectRoot);

        string[] memory cmdsBadLeaves = new string[](2);
        cmdsBadLeaves[0] = "node";
        cmdsBadLeaves[
            1
        ] = "test/utils/scripts/generate-bad-multiproof-leaves.js";
        bytes memory badLeaves = vm.ffi(cmdsBadLeaves);
        bytes32[] memory badLeavesDecoded = new bytes32[](3);
        (bytes32 arg1, bytes32 arg2, bytes32 arg3) = abi.decode(
            badLeaves,
            (bytes32, bytes32, bytes32)
        );
        badLeavesDecoded[0] = arg1;
        badLeavesDecoded[1] = arg2;
        badLeavesDecoded[2] = arg3;

        bool[] memory badProofFlags = decodeBadMultiProofProofFlags();
        bytes32[] memory badMultiProofDecoded = decodeBadMultiProofPayload();

        assertTrue(
            !merkleProofVerification.multi_proof_verify(
                badMultiProofDecoded,
                badProofFlags,
                bytes32(correctRoot),
                badLeavesDecoded
            )
        );
    }

    /**
     * @notice This is a unit test linked to OpenZeppelin's security advisory:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/security/advisories/GHSA-wprv-93r4-jj2p.
     * Note that 🐍 snekmate's implementation is not vulnerable by design,
     * as you cannot consume the out-of-bound `hashes` in Vyper. For further
     * insights also, see the following Twitter thread:
     * https://twitter.com/0xDACA/status/1669846430528286722.
     */
    function testMaliciousMultiProofVerify() public {
        /**
         * @dev Create a Merkle tree that contains a zero leaf at depth 1.
         */
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encode("real leaf"));
        leaves[1] = bytes32(0);
        bytes32 root = merkleGenerator.hashLeafPairs(leaves[0], leaves[1]);

        bytes32[] memory maliciousLeaves = new bytes32[](2);
        maliciousLeaves[0] = keccak256(abi.encode("malicious"));
        maliciousLeaves[1] = keccak256(abi.encode("leaves"));

        /**
         * @dev Now we can pass any malicious fake leaves as valid.
         */
        bytes32[] memory maliciousProof = new bytes32[](2);
        maliciousProof[0] = leaves[0];
        maliciousProof[1] = leaves[0];

        bool[] memory maliciousProofFlags = new bool[](3);
        maliciousProofFlags[0] = true;
        maliciousProofFlags[1] = true;
        maliciousProofFlags[2] = false;

        vm.expectRevert();
        merkleProofVerification.multi_proof_verify(
            maliciousProof,
            maliciousProofFlags,
            root,
            maliciousLeaves
        );
    }

    function testInvalidMultiProof() public {
        string[] memory cmdsCorrectRoot = new string[](2);
        cmdsCorrectRoot[0] = "node";
        cmdsCorrectRoot[1] = "test/utils/scripts/generate-root.js";
        bytes memory correctRoot = vm.ffi(cmdsCorrectRoot);

        string[] memory cmdsBadLeaves = new string[](2);
        cmdsBadLeaves[0] = "node";
        cmdsBadLeaves[
            1
        ] = "test/utils/scripts/generate-bad-multiproof-leaves.js";
        bytes memory badLeaves = vm.ffi(cmdsBadLeaves);
        bytes32[] memory badLeavesDecoded = new bytes32[](3);
        (bytes32 arg1, bytes32 arg2, bytes32 arg3) = abi.decode(
            badLeaves,
            (bytes32, bytes32, bytes32)
        );
        badLeavesDecoded[0] = arg1;
        badLeavesDecoded[1] = arg2;
        badLeavesDecoded[2] = arg3;

        bool[] memory badProofFlags = decodeBadMultiProofProofFlags();
        bytes32[] memory badMultiProofDecoded = decodeBadMultiProofPayload();

        bool[] memory badProofFlagsSliced = new bool[](3);
        badProofFlagsSliced[0] = badProofFlags[0];
        badProofFlagsSliced[1] = badProofFlags[2];
        badProofFlagsSliced[2] = badProofFlags[4];

        bytes32[] memory badMultiProofDecodedSliced = new bytes32[](3);
        badMultiProofDecodedSliced[0] = badMultiProofDecoded[0];
        badMultiProofDecodedSliced[1] = badMultiProofDecoded[2];
        badMultiProofDecodedSliced[2] = badMultiProofDecoded[4];

        bytes32[] memory badLeavesDecodedSliced = new bytes32[](2);
        badLeavesDecodedSliced[0] = badLeavesDecoded[0];
        badLeavesDecodedSliced[1] = badLeavesDecoded[2];

        vm.expectRevert(bytes("MerkleProof: invalid multiproof"));
        merkleProofVerification.multi_proof_verify(
            badMultiProofDecodedSliced,
            badProofFlags,
            bytes32(correctRoot),
            badLeavesDecoded
        );

        vm.expectRevert(bytes("MerkleProof: invalid multiproof"));
        merkleProofVerification.multi_proof_verify(
            badMultiProofDecoded,
            badProofFlagsSliced,
            bytes32(correctRoot),
            badLeavesDecoded
        );

        vm.expectRevert(bytes("MerkleProof: invalid multiproof"));
        merkleProofVerification.multi_proof_verify(
            badMultiProofDecoded,
            badProofFlags,
            bytes32(correctRoot),
            badLeavesDecodedSliced
        );
    }

    function testMultiProofEdgeCase1() public {
        bytes32[] memory leaves = new bytes32[](1);
        bytes32[] memory multiProof = new bytes32[](0);
        bool[] memory proofFlags = new bool[](0);

        leaves[0] = keccak256(bytes.concat(keccak256(abi.encode("a"))));

        /**
         * @dev Works for a Merkle tree containing a single leaf.
         */
        assertTrue(
            merkleProofVerification.multi_proof_verify(
                multiProof,
                proofFlags,
                leaves[0],
                leaves
            )
        );
    }

    function testMultiProofEdgeCase2() public {
        bytes32[] memory leaves = new bytes32[](0);
        bytes32[] memory multiProof = new bytes32[](1);
        bool[] memory proofFlags = new bool[](0);

        bytes32 root = keccak256(
            bytes.concat(keccak256(abi.encode("a", "b", "c")))
        );
        multiProof[0] = root;

        /**
         * @dev Can prove empty leaves.
         */
        assertTrue(
            merkleProofVerification.multi_proof_verify(
                multiProof,
                proofFlags,
                root,
                leaves
            )
        );
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/Vectorized/solady/blob/main/test/MerkleProofLib.t.sol.
     */
    function testFuzzVerify(
        bytes32[] calldata data,
        uint256 randomness
    ) public {
        vm.assume(data.length > 1);
        uint256 nodeIndex = randomness % data.length;
        bytes32 root = merkleGenerator.getRoot(data);
        bytes32[] memory proof = merkleGenerator.getProof(data, nodeIndex);
        bytes32 leaf = data[nodeIndex];
        assertTrue(merkleProofVerification.verify(proof, root, leaf));
        assertTrue(
            !merkleProofVerification.verify(
                proof,
                bytes32(uint256(root) ^ 1),
                leaf
            )
        );

        proof[0] = bytes32(uint256(proof[0]) ^ 1);
        assertTrue(!merkleProofVerification.verify(proof, root, leaf));
        assertTrue(
            !merkleProofVerification.verify(
                proof,
                bytes32(uint256(root) ^ 1),
                leaf
            )
        );
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/Vectorized/solady/blob/main/test/MerkleProofLib.t.sol.
     */
    function testFuzzMultiProofVerifySingleLeaf(
        bytes32[] calldata data,
        uint256 randomness
    ) public {
        vm.assume(data.length > 1);
        uint256 nodeIndex = randomness % data.length;
        bytes32 root = merkleGenerator.getRoot(data);
        bytes32[] memory proof = merkleGenerator.getProof(data, nodeIndex);
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = data[nodeIndex];
        bool[] memory proofFlags = new bool[](proof.length);
        assertTrue(
            merkleProofVerification.multi_proof_verify(
                proof,
                proofFlags,
                root,
                leaves
            )
        );
        assertTrue(
            !merkleProofVerification.multi_proof_verify(
                proof,
                proofFlags,
                bytes32(uint256(root) ^ 1),
                leaves
            )
        );

        proof[0] = bytes32(uint256(proof[0]) ^ 1);
        assertTrue(
            !merkleProofVerification.multi_proof_verify(
                proof,
                proofFlags,
                root,
                leaves
            )
        );
        assertTrue(
            !merkleProofVerification.multi_proof_verify(
                proof,
                proofFlags,
                bytes32(uint256(root) ^ 1),
                leaves
            )
        );
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/Vectorized/solady/blob/main/test/MerkleProofLib.t.sol.
     */
    function testFuzzVerifyMultiProofMultipleLeaves(
        bool damageProof,
        bool damageRoot,
        bool damageLeaves
    ) public {
        bool noDamage = true;

        bytes32 root = merkleGenerator.hashLeafPairs(
            merkleGenerator.hashLeafPairs(
                merkleGenerator.hashLeafPairs(bytes32("a"), bytes32("b")),
                merkleGenerator.hashLeafPairs(bytes32("c"), bytes32("d"))
            ),
            merkleGenerator.hashLeafPairs(bytes32("e"), bytes32("f"))
        );

        bytes32[] memory leaves = new bytes32[](3);
        leaves[0] = bytes32("d");
        leaves[1] = bytes32("e");
        leaves[2] = bytes32("f");

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32("c");
        proof[1] = merkleGenerator.hashLeafPairs(bytes32("b"), bytes32("a"));

        bool[] memory flags = new bool[](4);
        flags[0] = false;
        flags[1] = true;
        flags[2] = false;
        flags[3] = true;

        if (damageRoot) {
            noDamage = false;
            root = bytes32(uint256(root) ^ 1);
        }

        if (damageLeaves) {
            noDamage = false;
            leaves[0] = bytes32(uint256(leaves[0]) ^ 1);
        }

        if (damageProof && proof.length != 0) {
            noDamage = false;
            proof[0] = bytes32(uint256(proof[0]) ^ 1);
        }

        assertEq(
            merkleProofVerification.multi_proof_verify(
                proof,
                flags,
                root,
                leaves
            ),
            noDamage
        );
    }
}
