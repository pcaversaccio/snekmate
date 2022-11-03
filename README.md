# 🐍 snekmate

[![Test smart contracts](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml/badge.svg)](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**State-of-the-art**, **highly opinionated**, **hyper-optimised**, and **secure** 🐍Vyper smart contract building blocks.

> This is **experimental software** and is provided on an "as is" and "as available" basis. We **do not give any warranties** and **will not be liable for any losses** incurred through any use of this code base.

## 📜 Contracts

```ml
tokens
├─ ERC20 — "Modern and Gas-Efficient ERC-20 + EIP-2612 Implementation"
├─ ERC721 — "Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation"
├─ ERC1155 — "Modern and Gas-Efficient ERC-1155 Implementation"
utils
├─ ECDSA — "Elliptic Curve Digital Signature Algorithm (ECDSA) Functions"
├─ CreateAddress — "`CREATE` EVM Opcode Utility Function for Address Calculation"
├─ Create2Address — "`CREATE2` EVM Opcode Utility Functions for Address Calculations"
├─ EIP712DomainSeparator — "EIP-712 Domain Separator"
├─ MerkleProofVerification — "Merkle Tree Proof Verification Functions"
├─ Multicall — "Multicall Functions"
├─ SignatureChecker — "ECDSA and EIP-1271 Signature Verification Function"
├─ BatchDistributor — "Batch Sending Both Native and ERC-20 Tokens"
```

## 🙏🏼 Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [ApeAcademy](https://github.com/ApeAcademy)
- [batch-distributor](https://github.com/pcaversaccio/batch-distributor)
- [create-util](https://github.com/pcaversaccio/create-util)
- [disperse-research](https://github.com/banteg/disperse-research)
- [multicall](https://github.com/mds1/multicall)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Solmate](https://github.com/transmissions11/solmate)

## 💢 Disclaimer

![nobody-reads-ever-a-fucking-disclaimer](https://user-images.githubusercontent.com/25297591/167394075-1813e258-3b03-4bc8-9305-69126a07d57e.png)
