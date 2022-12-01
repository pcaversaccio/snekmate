const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const ethers = require("ethers");

const badElements = ["d", "e", "f"];
const merkleTree = StandardMerkleTree.of(
  badElements.map((c) => [c]),
  ["string"]
);

const badProof = merkleTree.getProof([badElements[0]]);

// eslint-disable-next-line no-undef
process.stdout.write(
  ethers.utils.defaultAbiCoder.encode(["bytes32"], badProof)
);
