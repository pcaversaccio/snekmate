# 🕓 Changelog

## `0.0.2` (Unreleased)

### 💥 New Features

- **Utility Functions**
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/Math.vy): Add `wad_ln` and `wad_exp` to the standard mathematical utility functions. ([#91](https://github.com/pcaversaccio/snekmate/pull/91))

### ♻️ Refactoring

- **Utility Functions**
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/Math.vy): Use directly 🐍 snekmate's [`log_2`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/Math.vy#L202) function in the internal calculation of `wad_cbrt`. ([#91](https://github.com/pcaversaccio/snekmate/pull/91))

## `0.0.1` (06-03-2023)

### 💥 New Features

- **Authentication**
  - [`Ownable`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/auth/Ownable.vy): Owner-based access control functions.
  - [`Ownable2Step`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/auth/Ownable2Step.vy): 2-step ownership transfer functions.
  - [`AccessControl`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/auth/AccessControl.vy): Multi-role-based access control functions.
- **Extensions**
  - [`ERC4626`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/extensions/ERC4626.vy): Modern and gas-efficient ERC-4626 tokenised vault implementation. ([#74](https://github.com/pcaversaccio/snekmate/pull/74))
- **Tokens**
  - [`ERC20`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/tokens/ERC20.vy): Modern and gas-efficient ERC-20 + EIP-2612 implementation. ([#17](https://github.com/pcaversaccio/snekmate/pull/17))
  - [`ERC721`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/tokens/ERC721.vy): Modern and gas-efficient ERC-721 + EIP-4494 implementation. ([#20](https://github.com/pcaversaccio/snekmate/pull/20))
  - [`ERC1155`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/tokens/ERC1155.vy): Modern and gas-efficient ERC-1155 implementation. ([#31](https://github.com/pcaversaccio/snekmate/pull/31))
- **Utility Functions**
  - [`Base64`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/Base64.vy): Base64 encoding and decoding functions. ([#47](https://github.com/pcaversaccio/snekmate/pull/47))
  - [`BatchDistributor`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/BatchDistributor.vy): Batch sending both native and ERC-20 tokens.
  - [`CreateAddress`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/CreateAddress.vy): `CREATE` EVM opcode utility function for address calculation.
  - [`Create2Address`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/Create2Address.vy): `CREATE2` EVM opcode utility functions for address calculations.
  - [`ECDSA`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/ECDSA.vy): Elliptic curve digital signature algorithm (ECDSA) functions.
  - [`SignatureChecker`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/SignatureChecker.vy): ECDSA and EIP-1271 signature verification functions.
  - [`EIP712DomainSeparator`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/EIP712DomainSeparator.vy): EIP-712 domain separator.
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/Math.vy): Standard mathematical utility functions. ([#74](https://github.com/pcaversaccio/snekmate/pull/74), [#77](https://github.com/pcaversaccio/snekmate/pull/77), [#86](https://github.com/pcaversaccio/snekmate/pull/86))
  - [`MerkleProofVerification`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/MerkleProofVerification.vy): Merkle tree proof verification functions. ([#30](https://github.com/pcaversaccio/snekmate/pull/30))
  - [`Multicall`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/Multicall.vy): Multicall functions.
