# 🕓 Changelog

## [`0.0.3`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.0.3) (12-10-2023)

### 💥 New Features

- **Extensions**
  - [`ERC2981`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/src/extensions/ERC2981.vy): An [`ERC-721`](https://eips.ethereum.org/EIPS/eip-721) and [`ERC-1155`](https://eips.ethereum.org/EIPS/eip-1155) compatible [`ERC-2981`](https://eips.ethereum.org/EIPS/eip-2981) reference implementation. ([#138](https://github.com/pcaversaccio/snekmate/pull/138))

### ♻️ Refactoring

- **Extensions**
  - [`ERC4626`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/src/extensions/ERC4626.vy):
    - Remove the non-standard `increase_allowance` and `decrease_allowance` functions. ([#160](https://github.com/pcaversaccio/snekmate/pull/160))
    - Optimise the method used to factor powers of two out of the denominator in `_mul_div`. ([#162](https://github.com/pcaversaccio/snekmate/pull/162))
- **Tokens**
  - [`ERC20`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/src/tokens/ERC20.vy):
    - Optimise the `set_minter` function to save one `SLOAD`. ([#154](https://github.com/pcaversaccio/snekmate/pull/154))
    - Remove the non-standard `increase_allowance` and `decrease_allowance` functions. ([#160](https://github.com/pcaversaccio/snekmate/pull/160))
  - [`ERC721`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/src/tokens/ERC721.vy): Optimise the `set_minter` function to save one `SLOAD`. ([#154](https://github.com/pcaversaccio/snekmate/pull/154))
  - [`ERC1155`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/src/tokens/ERC1155.vy): Optimise the `set_minter` function to save one `SLOAD`. ([#154](https://github.com/pcaversaccio/snekmate/pull/154))
- **Utility Functions**
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/src/utils/Math.vy): Optimise the method used to factor powers of two out of the denominator in `mul_div`. ([#153](https://github.com/pcaversaccio/snekmate/pull/153))
- **Vyper Contract Deployer**
  - [`VyperDeployer`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/lib/utils/VyperDeployer.sol): If you want to leverage 🐍 snekmate's [`VyperDeployer`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/lib/utils/VyperDeployer.sol) contract for your own testing, ensure that you compile the Vyper contracts with the same EVM version as configured in your `foundry.toml` file. The [`VyperDeployer`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/lib/utils/VyperDeployer.sol) contract offers two overloaded `deployContract` functions that allow the configuration of the target EVM version. Please note that since Vyper version [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) the default EVM version is set to `shanghai`. ([#161](https://github.com/pcaversaccio/snekmate/pull/161))

### 🥢 Test Coverage

- **Utility Functions**
  - [`MerkleProofVerificationTest`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/test/utils/MerkleProofVerification.t.sol): Add an additional test for a possible `multi_proof_verify` invariant violation. ([#137](https://github.com/pcaversaccio/snekmate/pull/137))

### ❗️ Breaking Change

- All 🐍 snekmate contracts now target the Vyper version [`0.3.10`](https://github.com/vyperlang/vyper/releases/tag/v0.3.10) ([#164](https://github.com/pcaversaccio/snekmate/pull/164)). It is strongly recommended to upgrade accordingly your local Vyper version prior to using the 🐍 snekmate contracts. **Important:** The default EVM version since Vyper version [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) is set to `shanghai` (i.e. the EVM includes the [`PUSH0`](https://eips.ethereum.org/EIPS/eip-3855) instruction). If you intend to deploy on an EVM chain with no `PUSH0` support, you must compile the 🐍 snekmate contracts with the `--evm-version paris` option; e.g. `vyper --evm-version paris utils/Math.vy`, or add the `# pragma evm-version paris` directive to the 🐍 snekmate contracts:

```vyper
# pragma version ^0.3.10
# pragma evm-version paris
# pragma optimize gas
"""
@title Modern and Gas-Efficient ERC-20 + EIP-2612 Implementation
...
"""


# @dev We import and implement the `ERC20` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC20
implements: ERC20
...
```

> The `# pragma optimize` directive has also been added in Vyper version [`0.3.10`](https://github.com/vyperlang/vyper/releases/tag/v0.3.10) (see PR [#3493](https://github.com/vyperlang/vyper/pull/3493)). Please refer to [here](https://docs.vyperlang.org/en/stable/compiling-a-contract.html#compiler-optimization-modes) to learn more about the different options `none`, `codesize`, and `gas` (default).

### 👀 Full Changelog

- [`v0.0.2...v0.0.3`](https://github.com/pcaversaccio/snekmate/compare/v0.0.2...v0.0.3)

## [`0.0.2`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.0.2) (07-06-2023)

### 💥 New Features

- **General**
  - All 🐍 snekmate contracts now contain an _Ethereum Natural Language Specification Format_ (NatSpec) `custom` field `@custom:contract-name`. The underlying rationale is that the block explorers plan to use `@custom:contract-name` as contract name and `@title` as fallback. ([#124](https://github.com/pcaversaccio/snekmate/pull/124))
- **Extensions**
  - [`ERC4626`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/extensions/ERC4626.vy): Implement additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
- **Tokens**
  - [`ERC20`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC20.vy): Implement additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
  - [`ERC721`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC721.vy): Implement additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
- **Utility Functions**
  - [`EIP712DomainSeparator`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/EIP712DomainSeparator.vy): Implement additionally the interface [`IERC5267`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/interfaces/IERC5267.vy). ([#129](https://github.com/pcaversaccio/snekmate/pull/129))
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

- All 🐍 snekmate contracts now target the Vyper version [`0.3.9`](https://github.com/vyperlang/vyper/releases/tag/v0.3.9). It is strongly recommended to upgrade accordingly your local Vyper version prior to using the 🐍 snekmate contracts. **Important:** The default EVM version since Vyper version [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) is set to `shanghai` (i.e. the EVM includes the [`PUSH0`](https://eips.ethereum.org/EIPS/eip-3855) instruction). If you intend to deploy on an EVM chain with no `PUSH0` support, you must compile the 🐍 snekmate contracts with the `--evm-version paris` option; e.g. `vyper --evm-version paris utils/Math.vy`. ([#122](https://github.com/pcaversaccio/snekmate/pull/122))

### 👀 Full Changelog

- [`v0.0.1...v0.0.2`](https://github.com/pcaversaccio/snekmate/compare/v0.0.1...v0.0.2)

## [`0.0.1`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.0.1) (06-03-2023)

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
