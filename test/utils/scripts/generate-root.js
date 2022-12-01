const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

const elements = require("./elements.js");
const merkleTree = StandardMerkleTree.of(elements.map(c => [c]), ["string"]);

// eslint-disable-next-line no-undef
process.stdout.write(merkleTree.root);
