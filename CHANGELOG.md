# 🕓 Changelog

## `0.0.2` (07-06-2023)

### 💥 New Features

- **General**
  - All 🐍 snekmate contracts now contain an _Ethereum Natural Language Specification Format_ (NatSpec) `custom` field `@custom:contract-name`. The underlying rationale is that the block explorers plan to use `@custom:contract-name` as contract name and `@title` as fallback. ([#124](https://github.com/pcaversaccio/snekmate/pull/124))
- **Extensions**
  - [`ERC4626`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/extensions/ERC4626.vy): Implements additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
- **Tokens**
  - [`ERC20`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC20.vy): Implements additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
  - [`ERC721`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC721.vy): Implements additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
- **Utility Functions**
  - [`EIP712DomainSeparator`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/EIP712DomainSeparator.vy): Implements additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/Math.vy): Add `wad_ln` and `wad_exp` to the standard mathematical utility functions. ([#91](https://github.com/pcaversaccio/snekmate/pull/91))

### ♻️ Refactoring

- **General**
  - All 🐍 snekmate contracts are now guaranteed to compile with the Vyper CLI flags `userdoc` and `devdoc`, and, if using the [Ape framework](https://github.com/ApeWorX/ape), with `ape compile`. ([#126](https://github.com/pcaversaccio/snekmate/pull/126))
- **Extensions**
  - [`ERC4626`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/extensions/ERC4626.vy):
    - Add `implements` interface `ERC20Detailed` and `ERC4626`. ([#125](https://github.com/pcaversaccio/snekmate/pull/125))
    - Use of the ternary operator introduced in Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) in the constructor for the `immutable` variable assignment of `_UNDERLYING_DECIMALS` instead of an `if-else` statement. ([#128](https://github.com/pcaversaccio/snekmate/pull/128))
- **Tokens**
  - [`ERC20`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC20.vy): Add `implements` interface `ERC20Detailed`. ([#125](https://github.com/pcaversaccio/snekmate/pull/125))
  - [`ERC721`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC721.vy): Add `implements` interface `IERC721Metadata`. ([#125](https://github.com/pcaversaccio/snekmate/pull/125))
- **Utility Functions**
  - [`Base64`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/Base64.vy): Use the shift operators `>>` and `<<` introduced in Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
  - [`ECDSA`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/ECDSA.vy): Use the shift operators `>>` and `<<` introduced in Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
  - [`SignatureChecker`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/SignatureChecker.vy): Use the shift operators `>>` and `<<` introduced in Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/Math.vy):
    - Use directly 🐍 snekmate's [`log_2`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/Math.vy#L202) function in the internal calculation of `wad_cbrt`. ([#91](https://github.com/pcaversaccio/snekmate/pull/91))
    - Use the shift operators `>>` and `<<` introduced in Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
    - Use of the ternary operator introduced in Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) in the function `ceil_div` instead of an `if-else` statement. ([#128](https://github.com/pcaversaccio/snekmate/pull/128))

### ❗️ Breaking Change

- All 🐍 snekmate contracts now target the Vyper version [`0.3.9`](https://github.com/vyperlang/vyper/releases/tag/v0.3.9). It is strongly recommended to upgrade accordingly your local Vyper version prior to using the 🐍 snekmate contracts. **Important:** The default EVM version since Vyper version `0.3.8` is set to `shanghai` (i.e. the EVM includes the [`PUSH0`](https://eips.ethereum.org/EIPS/eip-3855) instruction). If you intend to deploy on an EVM chain with no `PUSH0` support, you must compile the 🐍 snekmate contracts with the `--evm-version paris` option; e.g. `vyper --evm-version paris utils/Math.vy`. ([#122](https://github.com/pcaversaccio/snekmate/pull/122))

### 👀 Full Changelog

- [`v0.0.1...v0.0.2`](https://github.com/pcaversaccio/snekmate/compare/v0.0.1...v0.0.2)

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
