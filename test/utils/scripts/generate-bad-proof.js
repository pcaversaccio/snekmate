const { MerkleTree } = require("merkletreejs");
const ethers = require("ethers");

const badElements = ["d", "e", "f"];
const badMerkleTree = new MerkleTree(badElements);

const badProof = badMerkleTree.getHexProof(badElements[0]);

// eslint-disable-next-line no-undef
process.stdout.write(
  ethers.utils.defaultAbiCoder.encode(["bytes32"], badProof)
);
