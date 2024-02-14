# 🐍 snekmate

[![🕵️‍♂️ Test smart contracts](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml/badge.svg)](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml)
[![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL--3.0--only-blue)](https://www.gnu.org/licenses/agpl-3.0)
[![npm package](https://img.shields.io/npm/v/snekmate.svg?color=blue)](https://www.npmjs.com/package/snekmate)
[![PyPI package](https://img.shields.io/pypi/v/snekmate?color=blue)](https://pypi.org/project/snekmate)

<img src=https://github.com/pcaversaccio/snekmate/assets/25297591/a899251b-d22b-4cb3-8109-88facba53d6a width="1050"/>

**State-of-the-art**, **highly opinionated**, **hyper-optimised**, and **secure** 🐍Vyper smart contract building blocks.

> This is **experimental software** and is provided on an "as is" and "as available" basis. We **do not give any warranties** and **will not be liable for any losses** incurred through any use of this code base.

## 📜 Contracts

```ml
src
└── snekmate
    ├── auth
    │   ├── Ownable — "Owner-Based Access Control Functions"
    │   ├── Ownable2Step — "2-Step Ownership Transfer Functions"
    │   ├── AccessControl — "Multi-Role-Based Access Control Functions"
    │   └── interfaces
    │       └── IAccessControl — "AccessControl Interface Definition"
    ├── extensions
    │   ├── ERC2981 — "ERC-721 and ERC-1155 Compatible ERC-2981 Reference Implementation"
    │   ├── ERC4626 — "Modern and Gas-Efficient ERC-4626 Tokenised Vault Implementation"
    │   └── interfaces
    │       └── IERC2981 — "EIP-2981 Interface Definition"
    ├── governance
    │   └── TimelockController — "Multi-Role-Based Timelock Controller Reference Implementation"
    ├── tokens
    │   ├── ERC20 — "Modern and Gas-Efficient ERC-20 + EIP-2612 Implementation"
    │   ├── ERC721 — "Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation"
    │   ├── ERC1155 — "Modern and Gas-Efficient ERC-1155 Implementation"
    │   └── interfaces
    │       ├── IERC20Permit — "EIP-2612 Interface Definition"
    │       ├── IERC721Enumerable — "EIP-721 Optional Enumeration Interface Definition"
    │       ├── IERC721Metadata — "EIP-721 Optional Metadata Interface Definition"
    │       ├── IERC721Permit — "EIP-4494 Interface Definition"
    │       ├── IERC721Receiver — "EIP-721 Token Receiver Interface Definition"
    │       ├── IERC1155 — "EIP-1155 Interface Definition"
    │       ├── IERC1155MetadataURI — "EIP-1155 Optional Metadata Interface Definition"
    │       ├── IERC1155Receiver — "EIP-1155 Token Receiver Interface Definition"
    │       └── IERC4906 — "EIP-4906 Interface Definition"
    └── utils
        ├── Base64 — "Base64 Encoding and Decoding Functions"
        ├── BatchDistributor — "Batch Sending Both Native and ERC-20 Tokens"
        ├── CreateAddress — "`CREATE` EVM Opcode Utility Function for Address Calculation"
        ├── Create2Address — "`CREATE2` EVM Opcode Utility Functions for Address Calculations"
        ├── ECDSA — "Elliptic Curve Digital Signature Algorithm (ECDSA) Functions"
        ├── SignatureChecker — "ECDSA and EIP-1271 Signature Verification Functions"
        ├── EIP712DomainSeparator — "EIP-712 Domain Separator"
        ├── Math — "Standard Mathematical Utility Functions"
        ├── MerkleProofVerification — "Merkle Tree Proof Verification Functions"
        ├── Multicall — "Multicall Functions"
        └── interfaces
            └── IERC5267 — "EIP-5267 Interface Definition"
```

## 🎛 Installation

We offer three convenient ways to install the 🐍 snekmate contracts:

### 1️⃣ Foundry

You can install 🐍 snekmate via submodules using [Foundry](https://github.com/foundry-rs/foundry) with:

```console
forge install pcaversaccio/snekmate
```

> If you want to leverage 🐍 snekmate's [`VyperDeployer`](./lib/utils/VyperDeployer.sol) contract for your own testing, ensure that you compile the Vyper contracts with the same EVM version as configured in your `foundry.toml` file. The [`VyperDeployer`](./lib/utils/VyperDeployer.sol) contract offers two overloaded `deployContract` functions that allow the configuration of the target EVM version. Please note that since Vyper version [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) the default EVM version is set to `shanghai`.

### 2️⃣ PyPI

You can install 🐍 snekmate from [PyPI](https://pypi.org/project/snekmate) with:

```console
pip install snekmate
```

> You can use `pip install snekmate -t .` to install the contracts directly into the current working directory!

### 3️⃣ npm

You can install 🐍 snekmate from [npm](https://www.npmjs.com/package/snekmate) with:

```console
npm install --save-dev snekmate
```

Or if you are using [Yarn](https://yarnpkg.com):

```console
yarn add --dev snekmate
```

In case you are using [pnpm](https://pnpm.io), invoke:

```console
pnpm add --save-dev snekmate
```

> [!CAUTION]
> It is possible to install the latest versions of `main` or any other branch locally via `pip install git+https://github.com/pcaversaccio/snekmate.git@<branch>` or `forge install pcaversaccio/snekmate && forge update`. Each branch, **including the `main` branch**, must be understood as a development branch that should be avoided in favour of tagged releases. The release process includes security measures that the repository branches do not guarantee.

## 👩🏼‍⚖️ Tests

This repository contains [Foundry](https://github.com/foundry-rs/foundry)-based unit tests, property-based tests (i.e. fuzzing), and invariant tests for all contracts, if applicable. All tests are run as part of the CI pipeline [`test-contracts`](./.github/workflows/test-contracts.yml).

> [!NOTE]
> An _invariant_ is a property of a program that should always hold true. Fuzzing is a way of checking whether the invariant is falsifiable.

| **Contract**              | **Unit Tests** | **Property-Based Tests** | **Invariant Tests** |
| :------------------------ | :------------: | :----------------------: | :-----------------: |
| `Ownable`                 |       ✅       |            ✅            |         ✅          |
| `Ownable2Step`            |       ✅       |            ✅            |         ✅          |
| `AccessControl`           |       ✅       |            ✅            |         ✅          |
| `ERC2981`                 |       ✅       |            ✅            |         ✅          |
| `ERC4626`                 |       ✅       |            ✅            |         ✅          |
| `TimelockController`      |       ✅       |            ✅            |         ✅          |
| `ERC20`                   |       ✅       |            ✅            |         ✅          |
| `ERC721`                  |       ✅       |            ✅            |         ✅          |
| `ERC1155`                 |       ✅       |            ✅            |         ✅          |
| `Base64`                  |       ✅       |            ❌            |         ❌          |
| `BatchDistributor`        |       ✅       |            ✅            |         ✅          |
| `CreateAddress`           |       ✅       |            ✅            |         ❌          |
| `Create2Address`          |       ✅       |            ✅            |         ❌          |
| `ECDSA`                   |       ✅       |            ✅            |         ❌          |
| `SignatureChecker`        |       ✅       |            ✅            |         ❌          |
| `EIP712DomainSeparator`   |       ✅       |            ✅            |         ❌          |
| `Math`                    |       ✅       |            ✅            |         ❌          |
| `MerkleProofVerification` |       ✅       |            ✅            |         ❌          |
| `Multicall`               |       ✅       |            ❌            |         ❌          |

✅ Test Type Implemented &emsp; ❌ Test Type Not Implemented

## 🙏🏼 Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [ApeAcademy](https://github.com/ApeAcademy)
- [Batch Distributor](https://github.com/pcaversaccio/batch-distributor)
- [`CREATE` Factory](https://github.com/pcaversaccio/create-util)
- [Disperse Research](https://github.com/banteg/disperse-research)
- [Multicall](https://github.com/mds1/multicall)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [solady](https://github.com/Vectorized/solady)
- [solmate](https://github.com/transmissions11/solmate)

## 🫡 Contributing

🐍 snekmate only exists thanks to its [contributors](https://github.com/pcaversaccio/snekmate/graphs/contributors). There are many ways to get involved and contribute to our high-quality and secure smart contracts. Check out our [Contribution Guidelines](./CONTRIBUTING.md)!

## 💸 Donation

I am a strong advocate of the open-source and free software paradigm. However, if you feel my work deserves a donation, you can send it to this address: [`0xe9Fa0c8B5d7F79DeC36D3F448B1Ac4cEdedE4e69`](https://etherscan.io/address/0xe9Fa0c8B5d7F79DeC36D3F448B1Ac4cEdedE4e69). I can pledge that I will use this money to help fix more existing challenges in the Ethereum ecosystem 🤝.

## 💢 Disclaimer

<img src=https://user-images.githubusercontent.com/25297591/167394075-1813e258-3b03-4bc8-9305-69126a07d57e.png width="1050"/>
