# 🕓 Changelog

## [`0.1.2`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.1.2) (25-06-2025)

### 💥 New Features

- **Utility Functions**
  - [`block_hash`](https://github.com/pcaversaccio/snekmate/blob/v0.1.2/src/snekmate/utils/block_hash.vy): Add [EIP-2935](https://eips.ethereum.org/EIPS/eip-2935)-based utility functions. ([#316](https://github.com/pcaversaccio/snekmate/pull/316))
  - [`create`](https://github.com/pcaversaccio/snekmate/blob/v0.1.2/src/snekmate/utils/create.vy): Add `CREATE`-based deployment function. ([#323](https://github.com/pcaversaccio/snekmate/pull/323))
  - [`create2`](https://github.com/pcaversaccio/snekmate/blob/v0.1.2/src/snekmate/utils/create2.vy): Add `CREATE2`-based deployment function. ([#323](https://github.com/pcaversaccio/snekmate/pull/323))
  - [`create3`](https://github.com/pcaversaccio/snekmate/blob/v0.1.2/src/snekmate/utils/create3.vy): Add `CREATE3`-based address computation and deployment functions. ([#323](https://github.com/pcaversaccio/snekmate/pull/323))

### ♻️ Refactoring

- Explicitly set `nonreentrancy off` pragma. ([#320](https://github.com/pcaversaccio/snekmate/pull/320))

### 🐛 Bug Fixes

- **Extensions**
  - [`erc4626`](https://github.com/pcaversaccio/snekmate/blob/v0.1.2/src/snekmate/extensions/erc4626.vy): Fix `_max_withdraw` check in `withdraw` function to use `owner`. ([#327](https://github.com/pcaversaccio/snekmate/pull/327))

### 📄 Licensing

- Add the [MIT License](https://opensource.org/license/mit) as a dual-licensing option. ([#315](https://github.com/pcaversaccio/snekmate/pull/315))

### 🔖 Release Management

- Add provenance to `npm` release. ([#314](https://github.com/pcaversaccio/snekmate/pull/314))

### ❗️ Breaking Changes

- The contracts `create_address.vy` and `create2_address.vy` have been renamed to `create.vy` and `create2.vy`, respectively. In `create.vy`, the functions `_compute_address_rlp_self`, `_compute_address_rlp`, and `_convert_keccak256_2_address` have been renamed to `_compute_create_address_self`, `_compute_create_address`, and `_convert_keccak256_to_address`. Similarly, in `create2.vy`, the functions `_compute_address_self` and `_compute_address` have been renamed to `_compute_create2_address_self` and `_compute_create2_address`. ([#323](https://github.com/pcaversaccio/snekmate/pull/323))
- All 🐍 snekmate contracts now target the new 🐍Vyper [default EVM version](https://github.com/vyperlang/vyper/pull/4633) `prague` ([#331](https://github.com/pcaversaccio/snekmate/pull/331)). If you intend to deploy on an EVM chain with no `prague` support, you must compile — using the `cancun` EVM version as an example — the main contract that uses the 🐍 snekmate module contracts with the `--evm-version cancun` option; e.g. `vyper --evm-version cancun src/snekmate/tokens/mocks/erc20_mock.vy`, or add the `# pragma evm-version cancun` directive to the main contract that uses the 🐍 snekmate module contracts:

```vyper
# pragma version ~=0.4.3
# pragma evm-version cancun

...
```

### 👀 Full Changelog

- [`v0.1.1...v0.1.2`](https://github.com/pcaversaccio/snekmate/compare/v0.1.1...v0.1.2)

## [`0.1.1`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.1.1) (03-04-2025)

### 💥 New Features

- **Utility Functions**
  - [`pausable`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/utils/pausable.vy): Add a `pausable` contract module. ([#297](https://github.com/pcaversaccio/snekmate/pull/297))

### ♻️ Refactoring

- **Authentication**
  - [`ownable`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/auth/ownable.vy): Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
  - [`ownable_2step`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/auth/ownable_2step.vy): Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
  - [`access_control`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/auth/access_control.vy):
    - Use relative `interfaces` `import`s. ([#263](https://github.com/pcaversaccio/snekmate/pull/263))
    - Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
- **Extensions**
  - [`erc2981`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/extensions/erc2981.vy):
    - Use relative `interfaces` `import`s. ([#263](https://github.com/pcaversaccio/snekmate/pull/263))
    - Remove unnecessary `denominator` variable declaration. ([#267](https://github.com/pcaversaccio/snekmate/pull/267))
  - [`erc4626`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/extensions/erc4626.vy): Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
- **Governance**
  - [`timelock_controller`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/governance/timelock_controller.vy): Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
- **Tokens**
  - [`erc20`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/tokens/erc20.vy):
    - Use relative `interfaces` `import`s. ([#263](https://github.com/pcaversaccio/snekmate/pull/263))
    - Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
  - [`erc721`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/tokens/erc721.vy):
    - Use relative `interfaces` `import`s. ([#263](https://github.com/pcaversaccio/snekmate/pull/263))
    - Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
  - [`erc1155`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/tokens/erc1155.vy):
    - Use relative `interfaces` `import`s. ([#263](https://github.com/pcaversaccio/snekmate/pull/263))
    - Use keyword arguments for event instantiation. ([#280](https://github.com/pcaversaccio/snekmate/pull/280))
- **Utility Functions**
  - [`base64`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/utils/base64.vy): Use native hex string `x"..."` literals. ([#283](https://github.com/pcaversaccio/snekmate/pull/283))
  - [`message_hash_utils`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/utils/message_hash_utils.vy): Use native hex string `x"..."` literals. ([#283](https://github.com/pcaversaccio/snekmate/pull/283))
  - [`eip712_domain_separator`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/utils/eip712_domain_separator.vy):
    - Use relative `interfaces` `import`s. ([#263](https://github.com/pcaversaccio/snekmate/pull/263))
    - Use `bytes1` literal in `eip712Domain` function. ([#283](https://github.com/pcaversaccio/snekmate/pull/283))
  - [`math`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/utils/math.vy): Use mutable `internal` function parameters. ([#267](https://github.com/pcaversaccio/snekmate/pull/267))
  - [`multicall`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/utils/multicall.vy): Optimise `Batch`-based `for` loops. ([#287](https://github.com/pcaversaccio/snekmate/pull/287))

### 🥢 Test Coverage

- All 🐍 snekmate contract tests, i.e. unit tests, stateless and stateful fuzzing tests (including Echidna), and Halmos-based symbolic tests, are now also run against the experimental Venom backend. ([#268](https://github.com/pcaversaccio/snekmate/pull/268))

- **Tokens**
  - [`erc20`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/tokens/erc20.vy):
    - Use native `halmos` `createCalldata` cheat code. ([#273](https://github.com/pcaversaccio/snekmate/pull/273))
    - Use the EVM version `cancun` in `echidna`-based tests. ([#286](https://github.com/pcaversaccio/snekmate/pull/286))
  - [`erc721`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/tokens/erc721.vy):
    - Use native `halmos` `createCalldata` cheat code. ([#273](https://github.com/pcaversaccio/snekmate/pull/273))
    - Use the EVM version `cancun` in `echidna`-based tests. ([#286](https://github.com/pcaversaccio/snekmate/pull/286))
  - [`erc1155`](https://github.com/pcaversaccio/snekmate/blob/v0.1.1/src/snekmate/tokens/erc1155.vy): Use native `halmos` `createCalldata` cheat code. ([#273](https://github.com/pcaversaccio/snekmate/pull/273))

### 👀 Full Changelog

- [`v0.1.0...v0.1.1`](https://github.com/pcaversaccio/snekmate/compare/v0.1.0...v0.1.1)

## [`0.1.0`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.1.0) (26-06-2024)

> [!IMPORTANT]
> The aggregating pull request used to implement the subsequent changes is [#207](https://github.com/pcaversaccio/snekmate/pull/207).

### 💥 New Features

- **Authentication**
  - [`ownable`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/auth/ownable.vy): Make `ownable` module-friendly. ([#218](https://github.com/pcaversaccio/snekmate/pull/218))
  - [`ownable_2step`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/auth/ownable_2step.vy): Make `ownable_2step` module-friendly. ([#219](https://github.com/pcaversaccio/snekmate/pull/219))
  - [`access_control`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/auth/access_control.vy): Make `access_control` module-friendly. ([#216](https://github.com/pcaversaccio/snekmate/pull/216))
- **Extensions**
  - [`erc2981`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/extensions/erc2981.vy): Make `erc2981` module-friendly. ([#233](https://github.com/pcaversaccio/snekmate/pull/233))
  - [`erc4626`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/extensions/erc4626.vy): Make `erc4626` module-friendly. ([#236](https://github.com/pcaversaccio/snekmate/pull/236))
- **Governance**
  - [`timelock_controller`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/governance/timelock_controller.vy): Make `timelock_controller` module-friendly. ([#220](https://github.com/pcaversaccio/snekmate/pull/220))
- **Tokens**
  - [`erc20`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/tokens/erc20.vy): Make `erc20` module-friendly. ([#234](https://github.com/pcaversaccio/snekmate/pull/234))
  - [`erc721`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/tokens/erc721.vy): Make `erc721` module-friendly. ([#237](https://github.com/pcaversaccio/snekmate/pull/237))
  - [`erc1155`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/tokens/erc1155.vy): Make `erc1155` module-friendly. ([#238](https://github.com/pcaversaccio/snekmate/pull/238))
- **Utility Functions**
  - [`base64`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/base64.vy): Make `base64` module-friendly. ([#222](https://github.com/pcaversaccio/snekmate/pull/222))
  - [`batch_distributor`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/batch_distributor.vy): Make `batch_distributor` module-friendly. ([#223](https://github.com/pcaversaccio/snekmate/pull/223))
  - [`create_address`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/create_address.vy): Make `create_address` module-friendly. ([#224](https://github.com/pcaversaccio/snekmate/pull/224))
  - [`create2_address`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/create2_address.vy): Make `create2_address` module-friendly. ([#225](https://github.com/pcaversaccio/snekmate/pull/225))
  - [`ecdsa`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/ecdsa.vy): Make `ecdsa` module-friendly. ([#227](https://github.com/pcaversaccio/snekmate/pull/227))
  - [`p256`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/p256.vy): Add NIST P-256 (a.k.a. secp256r1) ECDSA verification function. ([#243](https://github.com/pcaversaccio/snekmate/pull/243))
  - [`message_hash_utils`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/message_hash_utils.vy): Move the `ecdsa` message hash methods to a separate `message_hash_utils` library module. ([#227](https://github.com/pcaversaccio/snekmate/pull/227))
  - [`signature_checker`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/signature_checker.vy): Make `signature_checker` module-friendly. ([#228](https://github.com/pcaversaccio/snekmate/pull/228))
  - [`eip712_domain_separator`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/eip712_domain_separator.vy): Make `eip712_domain_separator` module-friendly. ([#229](https://github.com/pcaversaccio/snekmate/pull/229))
  - [`math`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/math.vy): Make `math` module-friendly. ([#230](https://github.com/pcaversaccio/snekmate/pull/230))
  - [`merkle_proof_verification`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/merkle_proof_verification.vy): Make `merkle_proof_verification` module-friendly. ([#231](https://github.com/pcaversaccio/snekmate/pull/231))
  - [`multicall`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/multicall.vy): Make `multicall` module-friendly. ([#232](https://github.com/pcaversaccio/snekmate/pull/232))
- **🐍Vyper Contract Deployer**
  - [`VyperDeployer`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/lib/utils/VyperDeployer.sol): Improve error message in the event of a 🐍Vyper compilation error. ([#219](https://github.com/pcaversaccio/snekmate/pull/219))

### 🥢 Test Coverage

- **Tokens**
  - [`erc20`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/tokens/erc20.vy):
    - Add `echidna`-based `erc20` property tests. ([#239](https://github.com/pcaversaccio/snekmate/pull/239))
    - Add `halmos`-based `erc20` symbolic tests. ([#240](https://github.com/pcaversaccio/snekmate/pull/240))
  - [`erc721`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/tokens/erc721.vy):
    - Add `echidna`-based `erc721` property tests. ([#239](https://github.com/pcaversaccio/snekmate/pull/239))
    - Add `halmos`-based `erc721` symbolic tests. ([#240](https://github.com/pcaversaccio/snekmate/pull/240))
  - [`erc1155`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/tokens/erc1155.vy): Add `halmos`-based `erc1155` symbolic tests. ([#240](https://github.com/pcaversaccio/snekmate/pull/240))
- **Utility Functions**
  - [`math`](https://github.com/pcaversaccio/snekmate/blob/v0.1.0/src/snekmate/utils/math.vy): Add `halmos`-based `math` symbolic tests. ([#240](https://github.com/pcaversaccio/snekmate/pull/240))

### ❗️ Breaking Changes

- The file names of 🐍 snekmate module and mock contracts use the _snake case_ notation (e.g. `my_module.vy` or `my_module_mock.vy`), whilst the 🐍Vyper interface files `.vyi` use the _Pascal case_ notation prefixed with `I` (e.g. `IMyInterface.vyi`). ([#242](https://github.com/pcaversaccio/snekmate/pull/242))
- The mathematical utility functions `_log_2`, `_log_10`, and `_log_256` are renamed to `_log2`, `_log10`, and `_log256`. ([#242](https://github.com/pcaversaccio/snekmate/pull/242))
- All 🐍 snekmate contracts now target the new 🐍Vyper [default EVM version](https://github.com/vyperlang/vyper/pull/4029) `cancun` ([#245](https://github.com/pcaversaccio/snekmate/pull/245)). If you intend to deploy on an EVM chain with no `cancun` support, you must compile — using the `shanghai` EVM version as an example — the main contract that uses the 🐍 snekmate module contracts with the `--evm-version shanghai` option; e.g. `vyper --evm-version shanghai src/snekmate/tokens/mocks/erc20_mock.vy`, or add the `# pragma evm-version shanghai` directive to the main contract that uses the 🐍 snekmate module contracts:

```vyper
# pragma version ~=0.4.0
# pragma evm-version shanghai

...
```

### 👀 Full Changelog

- [`v0.0.5...v0.1.0`](https://github.com/pcaversaccio/snekmate/compare/v0.0.5...v0.1.0)

## [`0.0.5`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.0.5) (07-03-2024)

### 💥 New Features

- **Governance**
  - [`TimelockController`](https://github.com/pcaversaccio/snekmate/blob/v0.0.5/src/snekmate/governance/TimelockController.vy): A multi-role-based timelock controller reference implementation. ([#195](https://github.com/pcaversaccio/snekmate/pull/195))

### ♻️ Refactoring

- **Utility Functions**
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.5/src/snekmate/utils/Math.vy): Refactor the `is_negative` function into a proper `sign` function that returns the indication of the sign of a 32-byte signed integer. ([#187](https://github.com/pcaversaccio/snekmate/pull/187))
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.5/src/snekmate/utils/Math.vy): Rename the recently added `sign` function to `signum` to avoid any ambiguity with cryptographic signing utility functions. ([#188](https://github.com/pcaversaccio/snekmate/pull/188))
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.5/src/snekmate/utils/Math.vy): Optimise the zero point threshold in `wad_exp`. ([#189](https://github.com/pcaversaccio/snekmate/pull/189))

### 🔖 Release Management

- Implement `snekmate`-namespaced distribution package building for TestPyPI and PyPI. ([#204](https://github.com/pcaversaccio/snekmate/pull/204))
- Implement [`src` layout](https://setuptools.pypa.io/en/latest/userguide/package_discovery.html#src-layout) to enable an enhanced local `pip install git+https://github.com/pcaversaccio/snekmate.git@<branch>` building. ([#206](https://github.com/pcaversaccio/snekmate/pull/206))

### 👀 Full Changelog

- [`v0.0.4...v0.0.5`](https://github.com/pcaversaccio/snekmate/compare/v0.0.4...v0.0.5)

## [`0.0.4`](https://github.com/pcaversaccio/snekmate/releases/tag/v0.0.4) (13-10-2023)

### 🔒 Security Fixes

- **Utility Functions**
  - [`Multicall`](https://github.com/pcaversaccio/snekmate/blob/v0.0.4/src/utils/Multicall.vy): Remove the `multicall_value_self` function as the `msg.value` should not be trusted. ([#167](https://github.com/pcaversaccio/snekmate/pull/167))

### 👀 Full Changelog

- [`v0.0.3...v0.0.4`](https://github.com/pcaversaccio/snekmate/compare/v0.0.3...v0.0.4)

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
- **🐍Vyper Contract Deployer**
  - [`VyperDeployer`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/lib/utils/VyperDeployer.sol): If you want to leverage 🐍 snekmate's [`VyperDeployer`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/lib/utils/VyperDeployer.sol) contract for your own testing, ensure that you compile the 🐍Vyper contracts with the same EVM version as configured in your `foundry.toml` file. The [`VyperDeployer`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/lib/utils/VyperDeployer.sol) contract offers two overloaded `deployContract` functions that allow the configuration of the target EVM version. Please note that since 🐍Vyper version [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) the default EVM version is set to `shanghai`. ([#161](https://github.com/pcaversaccio/snekmate/pull/161))

### 🥢 Test Coverage

- **Utility Functions**
  - [`MerkleProofVerificationTest`](https://github.com/pcaversaccio/snekmate/blob/v0.0.3/test/utils/MerkleProofVerification.t.sol): Add an additional test for a possible `multi_proof_verify` invariant violation. ([#137](https://github.com/pcaversaccio/snekmate/pull/137))

### ❗️ Breaking Change

- All 🐍 snekmate contracts now target the 🐍Vyper version [`0.3.10`](https://github.com/vyperlang/vyper/releases/tag/v0.3.10) ([#164](https://github.com/pcaversaccio/snekmate/pull/164)). It is strongly recommended to upgrade accordingly your local 🐍Vyper version prior to using the 🐍 snekmate contracts. **Important:** The default EVM version since 🐍Vyper version [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) is set to `shanghai` (i.e. the EVM includes the [`PUSH0`](https://eips.ethereum.org/EIPS/eip-3855) instruction). If you intend to deploy on an EVM chain with no `PUSH0` support, you must compile the 🐍 snekmate contracts with the `--evm-version paris` option; e.g. `vyper --evm-version paris utils/Math.vy`, or add the `# pragma evm-version paris` directive to the 🐍 snekmate contracts:

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

> The `# pragma optimize` directive has also been added in 🐍Vyper version [`0.3.10`](https://github.com/vyperlang/vyper/releases/tag/v0.3.10) (see PR [#3493](https://github.com/vyperlang/vyper/pull/3493)). Please refer to [here](https://docs.vyperlang.org/en/stable/compiling-a-contract.html#compiler-optimization-modes) to learn more about the different options `none`, `codesize`, and `gas` (default).

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
  - All 🐍 snekmate contracts are now guaranteed to compile with the 🐍Vyper CLI flags `userdoc` and `devdoc`, and, if using the [Ape framework](https://github.com/ApeWorX/ape), with `ape compile`. ([#126](https://github.com/pcaversaccio/snekmate/pull/126))
- **Extensions**
  - [`ERC4626`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/extensions/ERC4626.vy):
    - Add `implements` interface `ERC20Detailed` and `ERC4626`. ([#125](https://github.com/pcaversaccio/snekmate/pull/125))
    - Use of the ternary operator introduced in 🐍Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) in the constructor for the `immutable` variable assignment of `_UNDERLYING_DECIMALS` instead of an `if-else` statement. ([#128](https://github.com/pcaversaccio/snekmate/pull/128))
- **Tokens**
  - [`ERC20`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC20.vy): Add `implements` interface `ERC20Detailed`. ([#125](https://github.com/pcaversaccio/snekmate/pull/125))
  - [`ERC721`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/tokens/ERC721.vy): Add `implements` interface `IERC721Metadata`. ([#125](https://github.com/pcaversaccio/snekmate/pull/125))
- **Utility Functions**
  - [`Base64`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/Base64.vy): Use the shift operators `>>` and `<<` introduced in 🐍Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
  - [`ECDSA`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/ECDSA.vy): Use the shift operators `>>` and `<<` introduced in 🐍Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
  - [`SignatureChecker`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/SignatureChecker.vy): Use the shift operators `>>` and `<<` introduced in 🐍Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
  - [`Math`](https://github.com/pcaversaccio/snekmate/blob/v0.0.2/src/utils/Math.vy):
    - Use directly 🐍 snekmate's [`log_2`](https://github.com/pcaversaccio/snekmate/blob/v0.0.1/src/utils/Math.vy#L202) function in the internal calculation of `wad_cbrt`. ([#91](https://github.com/pcaversaccio/snekmate/pull/91))
    - Use the shift operators `>>` and `<<` introduced in 🐍Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) instead of the `shift` instruction. ([#127](https://github.com/pcaversaccio/snekmate/pull/127))
    - Use of the ternary operator introduced in 🐍Vyper [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) in the function `ceil_div` instead of an `if-else` statement. ([#128](https://github.com/pcaversaccio/snekmate/pull/128))

### ❗️ Breaking Change

- All 🐍 snekmate contracts now target the 🐍Vyper version [`0.3.9`](https://github.com/vyperlang/vyper/releases/tag/v0.3.9). It is strongly recommended to upgrade accordingly your local 🐍Vyper version prior to using the 🐍 snekmate contracts. **Important:** The default EVM version since 🐍Vyper version [`0.3.8`](https://github.com/vyperlang/vyper/releases/tag/v0.3.8) is set to `shanghai` (i.e. the EVM includes the [`PUSH0`](https://eips.ethereum.org/EIPS/eip-3855) instruction). If you intend to deploy on an EVM chain with no `PUSH0` support, you must compile the 🐍 snekmate contracts with the `--evm-version paris` option; e.g. `vyper --evm-version paris utils/Math.vy`. ([#122](https://github.com/pcaversaccio/snekmate/pull/122))

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
