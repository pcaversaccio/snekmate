# 🐍 snekmate <!-- omit from toc -->

[![🕵️‍♂️ Test smart contracts](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml/badge.svg)](https://github.com/pcaversaccio/snekmate/actions/workflows/test-contracts.yml)
[![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL--3.0--only-blue)](https://www.gnu.org/licenses/agpl-3.0)
[![npm package](https://img.shields.io/npm/v/snekmate.svg?color=blue)](https://www.npmjs.com/package/snekmate)
[![PyPI package](https://img.shields.io/pypi/v/snekmate?color=blue)](https://pypi.org/project/snekmate)

<img src=https://github.com/pcaversaccio/snekmate/assets/25297591/a899251b-d22b-4cb3-8109-88facba53d6a width="1050"/>

**State-of-the-art**, **highly opinionated**, **hyper-optimised**, and **secure** 🐍Vyper smart contract building blocks.

> [!WARNING]
> This is **experimental software** and is provided on an "as is" and "as available" basis. We **do not give any warranties** and **will not be liable for any losses** incurred through any use of this code base.

- [📜 Contracts](#-contracts)
- [🎛 Installation](#-installation)
  - [1️⃣ PyPI](#1️⃣-pypi)
  - [2️⃣ Foundry](#2️⃣-foundry)
  - [3️⃣ npm](#3️⃣-npm)
- [🔧 Usage](#-usage)
- [👩🏼‍⚖️ Tests](#️-tests)
- [👮‍♀️ Audits](#️-audits)
- [🙏🏼 Acknowledgements](#-acknowledgements)
- [🫡 Contributing](#-contributing)
- [💸 Donation](#-donation)
- [📄 Licence](#-licence)
  - [⚖️ Dual-Licensing Option](#️-dual-licensing-option)
  - [📩 Requesting an MIT License](#-requesting-an-mit-license)
- [💢 Disclaimer](#-disclaimer)

## 📜 Contracts

```ml
src
└── snekmate
    ├── auth
    │   ├── ownable — "Owner-Based Access Control Functions"
    │   ├── ownable_2step — "2-Step Ownership Transfer Functions"
    │   ├── access_control — "Multi-Role-Based Access Control Functions"
    │   ├── interfaces
    │   │   └── IAccessControl — "AccessControl Interface Definition"
    │   └── mocks
    │       ├── ownable_mock — "`ownable` Module Reference Implementation"
    │       ├── ownable_2step_mock — "`ownable_2step` Module Reference Implementation"
    │       └── access_control_mock — "`access_control` Module Reference Implementation"
    ├── extensions
    │   ├── erc2981 — "ERC-721 and ERC-1155 Compatible ERC-2981 Reference Implementation"
    │   ├── erc4626 — "Modern and Gas-Efficient ERC-4626 Tokenised Vault Implementation"
    │   ├── interfaces
    │   │   └── IERC2981 — "EIP-2981 Interface Definition"
    │   └── mocks
    │       ├── erc2981_mock — "`erc2981` Module Reference Implementation"
    │       └── erc4626_mock — "`erc4626` Module Reference Implementation"
    ├── governance
    │   ├── timelock_controller — "Multi-Role-Based Timelock Controller Reference Implementation"
    │   └── mocks
    │       └── timelock_controller_mock — "`timelock_controller` Module Reference Implementation"
    ├── tokens
    │   ├── erc20 — "Modern and Gas-Efficient ERC-20 + EIP-2612 Implementation"
    │   ├── erc721 — "Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation"
    │   ├── erc1155 — "Modern and Gas-Efficient ERC-1155 Implementation"
    │   ├── interfaces
    │   │   ├── IERC20Permit — "EIP-2612 Interface Definition"
    │   │   ├── IERC721Enumerable — "EIP-721 Optional Enumeration Interface Definition"
    │   │   ├── IERC721Metadata — "EIP-721 Optional Metadata Interface Definition"
    │   │   ├── IERC721Permit — "EIP-4494 Interface Definition"
    │   │   ├── IERC721Receiver — "EIP-721 Token Receiver Interface Definition"
    │   │   ├── IERC1155 — "EIP-1155 Interface Definition"
    │   │   ├── IERC1155MetadataURI — "EIP-1155 Optional Metadata Interface Definition"
    │   │   ├── IERC1155Receiver — "EIP-1155 Token Receiver Interface Definition"
    │   │   └── IERC4906 — "EIP-4906 Interface Definition"
    │   └── mocks
    │       ├── erc20_mock — "`erc20` Module Reference Implementation"
    │       ├── erc721_mock — "`erc721` Module Reference Implementation"
    │       └── erc1155_mock — "`erc1155` Module Reference Implementation"
    └── utils
        ├── base64 — "Base64 Encoding and Decoding Functions"
        ├── batch_distributor — "Batch Sending Both Native and ERC-20 Tokens"
        ├── block_hash — "Utility Functions to Access Historical Block Hashes"
        ├── create — "`CREATE` EVM Opcode Utility Functions"
        ├── create2 — "`CREATE2` EVM Opcode Utility Functions"
        ├── create3 — "`CREATE3`-Based Utility Functions"
        ├── ecdsa — "Elliptic Curve Digital Signature Algorithm (ECDSA) Secp256k1-Based Functions"
        ├── p256 — "Elliptic Curve Digital Signature Algorithm (ECDSA) Secp256r1-Based Functions"
        ├── message_hash_utils — "Signature Message Hash Utility Functions"
        ├── signature_checker — "ECDSA and EIP-1271 Signature Verification Functions"
        ├── eip712_domain_separator — "EIP-712 Domain Separator"
        ├── eip7702_utils — "EIP-7702 Utility Functions"
        ├── math — "Standard Mathematical Utility Functions"
        ├── merkle_proof_verification — "Merkle Tree Proof Verification Functions"
        ├── multicall — "Multicall Functions"
        ├── pausable — "Pausable Functions"
        ├── interfaces
        │   ├── IERC1271 — "EIP-1271 Interface Definition"
        │   └── IERC5267 — "EIP-5267 Interface Definition"
        └── mocks
            ├── base64_mock — "`base64` Module Reference Implementation"
            ├── batch_distributor_mock — "`batch_distributor` Module Reference Implementation"
            ├── block_hash_mock — "`block_hash` Module Reference Implementation"
            ├── create_mock — "`create` Module Reference Implementation"
            ├── create2_mock — "`create2` Module Reference Implementation"
            ├── create3_mock — "`create3` Module Reference Implementation"
            ├── ecdsa_mock — "`ecdsa` Module Reference Implementation"
            ├── p256_mock — "`p256` Module Reference Implementation"
            ├── message_hash_utils_mock — "`message_hash_utils` Module Reference Implementation"
            ├── signature_checker_mock — "`signature_checker` Module Reference Implementation"
            ├── eip712_domain_separator_mock — "`eip712_domain_separator` Module Reference Implementation"
            ├── eip7702_utils_mock — "`eip7702_utils` Module Reference Implementation"
            ├── math_mock — "`math` Module Reference Implementation"
            ├── merkle_proof_verification_mock — "`merkle_proof_verification` Module Reference Implementation"
            ├── multicall_mock — "`multicall` Module Reference Implementation"
            └── pausable_mock — "`pausable` Module Reference Implementation"
```

## 🎛 Installation

> [!IMPORTANT]  
> 🐍 snekmate uses a [ZeroVer](https://0ver.org)-based versioning scheme. This means 🐍 snekmate's major version will never exceed the first and most important number in computing: zero.

We offer three convenient ways to install the 🐍 snekmate contracts:

### 1️⃣ PyPI

You can install 🐍 snekmate from [PyPI](https://pypi.org/project/snekmate) with:

```console
pip install snekmate
```

> When using the 🐍Vyper CLI, the search path [defaults](https://docs.vyperlang.org/en/latest/structure-of-a-contract.html#searching-for-imports) to the current working directory and the Python [`sys.path`](https://docs.python.org/3.15/library/sys.html#sys.path). As a result, all imported 🐍 snekmate contracts (e.g. `from snekmate.tokens import erc20`) are seamlessly located during compilation.

### 2️⃣ Foundry

You can install 🐍 snekmate via submodules using [Foundry](https://github.com/foundry-rs/foundry) with:

```console
forge install pcaversaccio/snekmate
```

> [!NOTE]
> If you want to leverage 🐍 snekmate's [`VyperDeployer`](./lib/utils/VyperDeployer.sol) contract for your own testing, ensure that you compile the 🐍Vyper contracts with the same EVM version as configured in your `foundry.toml` file. The [`VyperDeployer`](./lib/utils/VyperDeployer.sol) contract offers two overloaded `deployContract` functions that allow the configuration of the target EVM version. Please note that since 🐍Vyper version [`0.4.3`](https://github.com/vyperlang/vyper/releases/tag/v0.4.3) the default EVM version is set to `prague`. Furthermore, the [`VyperDeployer`](./lib/utils/VyperDeployer.sol) contract relies on the Python script [`compile.py`](./lib/utils/compile.py) for successful compilation and deployment. Always use the [`VyperDeployer`](./lib/utils/VyperDeployer.sol) contract alongside with the aforementioned script.

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

If you are a [Bun](https://bun.sh) user, run:

```console
bun add --dev snekmate
```

> [!CAUTION]
> It is possible to install the latest versions of `main` or any other branch locally via `pip install git+https://github.com/pcaversaccio/snekmate.git@<branch>` or `forge install pcaversaccio/snekmate && forge update`. Each branch, **including the `main` branch**, must be understood as a development branch that should be avoided in favour of tagged releases. The release process includes security measures that the repository branches do not guarantee.

## 🔧 Usage

🐍Vyper favours code reuse through composition rather than inheritance (Solidity inheritance makes it easy to break the [Liskov Substitution Principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle)). A 🐍Vyper module encapsulates everything required for code reuse, from type and function declarations to state. **All 🐍 snekmate contracts are 🐍Vyper modules.** Thus, many of the 🐍 snekmate contracts do not compile independently, but you must `import` and `initializes` them. Please note that if a module is _stateless_, it does not require the keyword `initializes` (or `uses`) for initialisation (or usage). Each module contract has an associated mock contract in the `mock/` directory, which is part of the associated contract subdirectory. These mock contracts are very illustrative of how 🐍 snekmate contracts can be used as 🐍Vyper modules.

> [!IMPORTANT]
> All 🐍 snekmate contracts are very well documented in the form of general code and [NatSpec](https://docs.vyperlang.org/en/latest/natspec.html) comments. There are no shortcuts – if you are importing specific logic, read the documentation!

Please read [here](https://docs.vyperlang.org/en/latest/using-modules.html) to learn more about using 🐍Vyper modules.

## 👩🏼‍⚖️ Tests

This repository contains [Foundry](https://github.com/foundry-rs/foundry)-based unit tests, property-based tests (i.e. stateless fuzzing), and invariant tests (i.e. stateful fuzzing) for all contracts, if applicable. All tests are run as part of the CI pipeline [`test-contracts`](./.github/workflows/test-contracts.yml).

> [!NOTE]
> An _invariant_ is a property of a program that should always hold true. Fuzzing is a way of checking whether the invariant is falsifiable.

| **Contract**                | **Unit Tests** | **Property-Based Tests** | **Invariant Tests** |
| :-------------------------- | :------------: | :----------------------: | :-----------------: |
| `ownable`                   |       ✅       |            ✅            |         ✅          |
| `ownable_2step`             |       ✅       |            ✅            |         ✅          |
| `access_control`            |       ✅       |            ✅            |         ✅          |
| `erc2981`                   |       ✅       |            ✅            |         ✅          |
| `erc4626`                   |       ✅       |            ✅            |         ✅          |
| `timelock_controller`       |       ✅       |            ✅            |         ✅          |
| `erc20`                     |       ✅       |            ✅            |         ✅          |
| `erc721`                    |       ✅       |            ✅            |         ✅          |
| `erc1155`                   |       ✅       |            ✅            |         ✅          |
| `base64`                    |       ✅       |            ❌            |         ❌          |
| `batch_distributor`         |       ✅       |            ✅            |         ✅          |
| `block_hash`                |       ✅       |            ✅            |         ❌          |
| `create`                    |       ✅       |            ✅            |         ❌          |
| `create2`                   |       ✅       |            ✅            |         ❌          |
| `create3`                   |       ✅       |            ✅            |         ❌          |
| `ecdsa`                     |       ✅       |            ✅            |         ❌          |
| `p256`                      |       ✅       |            ✅            |         ❌          |
| `message_hash_utils`        |       ✅       |            ✅            |         ❌          |
| `signature_checker`         |       ✅       |            ✅            |         ❌          |
| `eip712_domain_separator`   |       ✅       |            ✅            |         ❌          |
| `eip7702_utils`             |       ✅       |            ✅            |         ❌          |
| `math`                      |       ✅       |            ✅            |         ❌          |
| `merkle_proof_verification` |       ✅       |            ✅            |         ❌          |
| `multicall`                 |       ✅       |            ❌            |         ❌          |
| `pausable`                  |       ✅       |            ✅            |         ✅          |

✅ Test Type Implemented &emsp; ❌ Test Type Not Implemented

Furthermore, the [`echidna`](https://github.com/crytic/echidna)-based [property](https://github.com/crytic/properties) tests for the [`erc20`](./src/snekmate/tokens/erc20.vy) and [`erc721`](./src/snekmate/tokens/erc721.vy) contracts are available in the [`test/tokens/echidna/`](./test/tokens/echidna) directory. You can run the tests by invoking:

```console
# Run Echidna ERC-20 property tests.
~$ FOUNDRY_PROFILE=echidna echidna test/tokens/echidna/ERC20Properties.sol --contract CryticERC20ExternalHarness --config test/echidna.yaml

# Run Echidna ERC-721 property tests.
~$ FOUNDRY_PROFILE=echidna echidna test/tokens/echidna/ERC721Properties.sol --contract CryticERC721ExternalHarness --config test/echidna.yaml
```

Eventually, the [`halmos`](https://github.com/a16z/halmos)-based symbolic tests for the [`erc20`](./src/snekmate/tokens/erc20.vy), [`erc721`](./src/snekmate/tokens/erc721.vy), [`erc1155`](./src/snekmate/tokens/erc1155.vy), and [`math`](./src/snekmate/utils/math.vy) contracts are available in the [`test/tokens/halmos/`](./test/tokens/halmos) and [`test/utils/halmos/`](./test/utils/halmos) directories. You can run the tests by invoking:

> [!IMPORTANT]
> You must install the latest [Yices 2](https://github.com/SRI-CSL/yices2) and [Bitwuzla](https://github.com/bitwuzla/bitwuzla) SMT solvers, as well as the [`jsi`](https://github.com/a16z/jsi) tool, before invoking the [`halmos`](https://github.com/a16z/halmos)-based symbolic tests.

```console
# Run Halmos ERC-20 symbolic tests.
~$ FOUNDRY_PROFILE=halmos halmos --contract ERC20TestHalmos --config test/halmos.toml

# Run Halmos ERC-721 symbolic tests.
~$ FOUNDRY_PROFILE=halmos halmos --contract ERC721TestHalmos --config test/halmos.toml

# Run Halmos ERC-1155 symbolic tests. Be careful, this is a time-consuming operation.
~$ FOUNDRY_PROFILE=halmos halmos --contract ERC1155TestHalmos --config test/halmos.toml

# Run Halmos math symbolic tests.
~$ FOUNDRY_PROFILE=halmos halmos --contract MathTestHalmos --config test/halmos.toml
```

> [!TIP]
> If you encounter any issues, please ensure that you have the [latest](https://github.com/vyperlang/vyper/releases) 🐍Vyper version installed locally.

## 👮‍♀️ Audits

Although the 🐍 snekmate contracts have not (yet) undergone a full comprehensive audit, selected library modules integrated into specific protocols (such as Curve) have been thoroughly reviewed within the scope of prior audits. The corresponding audit reports are available [here](./audits).

## 🙏🏼 Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [ApeAcademy](https://github.com/ApeAcademy)
- [Batch Distributor](https://github.com/pcaversaccio/batch-distributor)
- [`CREATE` Factory](https://github.com/pcaversaccio/create-util)
- [Disperse Research](https://github.com/banteg/disperse-research)
- [Multicall](https://github.com/mds1/multicall)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Solady](https://github.com/Vectorized/solady)
- [Solmate](https://github.com/transmissions11/solmate)

## 🫡 Contributing

🐍 snekmate only exists thanks to its [contributors](https://github.com/pcaversaccio/snekmate/graphs/contributors). There are many ways to get involved and contribute to our high-quality and secure smart contracts. Check out our [Contribution Guidelines](./CONTRIBUTING.md)!

## 💸 Donation

I am a strong advocate of the open-source and free software paradigm. However, if you feel my work deserves a donation, you can send it to this address: [`0xe9Fa0c8B5d7F79DeC36D3F448B1Ac4cEdedE4e69`](https://etherscan.io/address/0xe9Fa0c8B5d7F79DeC36D3F448B1Ac4cEdedE4e69). I can pledge that I will use this money to help fix more existing challenges in the Ethereum ecosystem 🤝.

## 📄 Licence

This software is released under the [GNU Affero General Public License v3.0 only](./LICENSE) (AGPL-3.0-only) **by default**.

We believe in fostering a collaborative and open ecosystem. The [AGPL-3.0-only](./LICENSE) licence keeps the code free, the knowledge shared, and the doors open. It stands as a quiet rebellion against control, a promise that what is built in the open will remain in the open, owned by no one and available to all.

### ⚖️ Dual-Licensing Option

We understand that [AGPL-3.0-only](./LICENSE)-licensed software may not be suitable for all use cases, particularly in cases involving:

- Proprietary or closed-source projects,
- Licence incompatibilities, or
- Commercial applications with conflicting requirements.

For such scenarios, we offer an alternative licence under the [MIT License](https://opensource.org/license/mit), granted at our sole discretion.

### 📩 Requesting an MIT License

If you have **substantial** reasons for requiring a more permissive licence, such as those outlined above, feel free to contact us via [email](mailto:pascal.caversaccio@hotmail.ch) to request access to the software under the [MIT License](https://opensource.org/license/mit).

Each request is evaluated on a case-by-case basis, and we will provide the [MIT License](https://opensource.org/license/mit) if deemed appropriate.

## 💢 Disclaimer

<img src=https://user-images.githubusercontent.com/25297591/167394075-1813e258-3b03-4bc8-9305-69126a07d57e.png width="1050"/>
