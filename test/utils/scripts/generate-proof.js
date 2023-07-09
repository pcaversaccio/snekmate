const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { AbiCoder } = require("ethers");

const elements = require("./elements.js");
const merkleTree = StandardMerkleTree.of(
  elements.map((c) => [c]),
  ["string"],
);

const proof = merkleTree.getProof([elements[0]]);

// eslint-disable-next-line no-undef
process.stdout.write(
  AbiCoder.defaultAbiCoder().encode(Array(6).fill("bytes32"), proof),
);
