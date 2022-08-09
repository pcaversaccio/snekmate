const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const ethers = require('ethers');

const elements = require('./elements.js')
const merkleTree = new MerkleTree(elements, keccak256, { hashLeaves: true, sortPairs: true });

const leaf = "0x" + keccak256(elements[0]).toString('hex');
const proof = merkleTree.getHexProof(leaf);

process.stdout.write(ethers.utils.defaultAbiCoder.encode(["bytes32", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32"], proof));
