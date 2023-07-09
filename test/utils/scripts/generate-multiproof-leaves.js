const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { AbiCoder } = require("ethers");

const elements = require("./elements.js");
const merkleTree = StandardMerkleTree.of(
  elements.map((c) => [c]),
  ["string"],
);

const idx = require("./multiproof-indices.js");
const { leaves } = merkleTree.getMultiProof(idx);
const hashedLeaves = leaves.map((c) => merkleTree.leafHash(c));

// eslint-disable-next-line no-undef
process.stdout.write(
  AbiCoder.defaultAbiCoder().encode(Array(3).fill("bytes32"), hashedLeaves),
);
