const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const ethers = require("ethers");

const elements = require("./elements.js");
const merkleTree = StandardMerkleTree.of(
  elements.map((c) => [c]),
  ["string"]
);

const proof = merkleTree.getProof([elements[0]]);

// eslint-disable-next-line no-undef
process.stdout.write(
  ethers.utils.defaultAbiCoder.encode(
    ["bytes32", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32"],
    proof
  )
);
