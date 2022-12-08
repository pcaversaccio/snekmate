const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const ethers = require("ethers");

const elements = require("./elements.js");
const merkleTree = StandardMerkleTree.of(
  elements.map((c) => [c]),
  ["string"]
);

const idx = require("./multiproof-indices.js");
const { proofFlags } = merkleTree.getMultiProof(idx);

// eslint-disable-next-line no-undef
process.stdout.write(
  ethers.utils.defaultAbiCoder.encode(Array(10).fill("bool"), proofFlags)
);
