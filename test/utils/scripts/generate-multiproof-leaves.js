const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const ethers = require("ethers");

const elements = require("./elements.js");
const merkleTree = StandardMerkleTree.of(
  elements.map((c) => [c]),
  ["string"]
);

const idx = require("./multiproof-indices.js");
const { leaves } = merkleTree.getMultiProof(idx);
const hashedLeaves = leaves.map((c) => merkleTree.leafHash(c));

// eslint-disable-next-line no-undef
process.stdout.write(
  ethers.utils.defaultAbiCoder.encode(Array(3).fill("bytes32"), hashedLeaves)
);
