# 🕓 Changelog

## `0.0.1` (06-03-2023)

### New Features

- **Authentication**
  - `Ownable`: Owner-based access control functions.
  - `Ownable2Step`: 2-step ownership transfer functions.
  - `AccessControl`: Multi-role-based access control functions.
- **Extensions**
  - `ERC4626`: Modern and gas-efficient ERC-4626 tokenised vault implementation. ([#74](https://github.com/pcaversaccio/snekmate/pull/74))
- **Tokens**
  - `ERC20`: Modern and gas-efficient ERC-20 + EIP-2612 implementation. ([#17](https://github.com/pcaversaccio/snekmate/pull/17))
  - `ERC721`: Modern and gas-efficient ERC-721 + EIP-4494 implementation. ([#20](https://github.com/pcaversaccio/snekmate/pull/20))
  - `ERC1155`: Modern and gas-efficient ERC-1155 implementation. ([#31](https://github.com/pcaversaccio/snekmate/pull/31))
- **Utility Functions**
  - `Base64`: Base64 encoding and decoding functions. ([#47](https://github.com/pcaversaccio/snekmate/pull/47))
  - `BatchDistributor`: Batch sending both native and ERC-20 tokens.
  - `CreateAddress`: `CREATE` EVM opcode utility function for address calculation.
  - `Create2Address`: `CREATE2` EVM opcode utility functions for address calculations.
  - `ECDSA`: Elliptic curve digital signature algorithm (ECDSA) functions.
  - `SignatureChecker`: ECDSA and EIP-1271 signature verification functions.
  - `EIP712DomainSeparator`: EIP-712 domain separator.
  - `Math`: Standard mathematical utility functions. ([#74](https://github.com/pcaversaccio/snekmate/pull/74), [#77](https://github.com/pcaversaccio/snekmate/pull/77), [#86](https://github.com/pcaversaccio/snekmate/pull/86))
  - `MerkleProofVerification`: Merkle tree proof verification functions. ([#30](https://github.com/pcaversaccio/snekmate/pull/30))
  - `Multicall`: Multicall functions.
