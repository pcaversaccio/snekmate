const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { AbiCoder } = require("ethers");

const elements = require("./elements.js");
const merkleTree = new MerkleTree(elements, keccak256, {
  hashLeaves: true,
  sortPairs: true,
});

const leaf = "0x" + keccak256(elements[0]).toString("hex");
const proof = merkleTree.getHexProof(leaf);

// eslint-disable-next-line no-undef
process.stdout.write(
  AbiCoder.defaultAbiCoder().encode(Array(7).fill("bytes32"), proof),
);
