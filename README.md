# π snekmate

[![Test smart contracts](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml/badge.svg)](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**State-of-the-art**, **highly opinionated**, **hyper-optimised**, and **secure** πVyper smart contract building blocks.

> This is **experimental software** and is provided on an "as is" and "as available" basis. We **do not give any warranties** and **will not be liable for any losses** incurred through any use of this code base.

## π Contracts

```ml
src
ββ auth
β  ββ Ownable β "Owner-Based Access Control Functions"
β  ββ Ownable2Step β "2-Step Ownership Transfer Functions"
β  ββ AccessControl β "Multi-Role-Based Access Control Functions"
ββ extensions
β  ββ ERC4626 β "ERC-4626 Tokenised Vault Implementation (TBD)"
ββ tokens
β  ββ ERC20 β "Modern and Gas-Efficient ERC-20 + EIP-2612 Implementation"
β  ββ ERC721 β "Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation"
β  ββ ERC1155 β "Modern and Gas-Efficient ERC-1155 Implementation (TBD)"
ββ utils
   ββ ECDSA β "Elliptic Curve Digital Signature Algorithm (ECDSA) Functions"
   ββ CreateAddress β "`CREATE` EVM Opcode Utility Function for Address Calculation"
   ββ Create2Address β "`CREATE2` EVM Opcode Utility Functions for Address Calculations"
   ββ EIP712DomainSeparator β "EIP-712 Domain Separator"
   ββ MerkleProofVerification β "Merkle Tree Proof Verification Functions"
   ββ Multicall β "Multicall Functions"
   ββ SignatureChecker β "ECDSA and EIP-1271 Signature Verification Function"
   ββ BatchDistributor β "Batch Sending Both Native and ERC-20 Tokens"
   ββ Base64 β "Base64 Encoding and Decoding Functions"
```

## ππΌ Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [ApeAcademy](https://github.com/ApeAcademy)
- [batch-distributor](https://github.com/pcaversaccio/batch-distributor)
- [create-util](https://github.com/pcaversaccio/create-util)
- [disperse-research](https://github.com/banteg/disperse-research)
- [multicall](https://github.com/mds1/multicall)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Solmate](https://github.com/transmissions11/solmate)

## π«‘ Contributing

π snekmate only exists thanks to its [contributors](https://github.com/pcaversaccio/snekmate/graphs/contributors). There are many ways to get involved and contribute to our high-quality and secure smart contracts. Check out our [Contribution Guidelines](./CONTRIBUTING.md)!

## π’ Disclaimer

<img src=https://user-images.githubusercontent.com/25297591/167394075-1813e258-3b03-4bc8-9305-69126a07d57e.png width="1050"/>
