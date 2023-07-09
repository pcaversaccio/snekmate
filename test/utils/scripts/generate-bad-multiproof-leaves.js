const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { AbiCoder } = require("ethers");

const badElements = require("./multiproof-bad-elements.js");
const merkleTree = StandardMerkleTree.of(
  badElements.map((c) => [c]),
  ["string"],
);

const idx = require("./multiproof-bad-indices.js");
const { leaves } = merkleTree.getMultiProof(idx);
const hashedBadLeaves = leaves.map((c) => merkleTree.leafHash(c));

// eslint-disable-next-line no-undef
process.stdout.write(
  AbiCoder.defaultAbiCoder().encode(Array(3).fill("bytes32"), hashedBadLeaves),
);
