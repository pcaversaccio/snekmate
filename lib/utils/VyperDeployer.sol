// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Create} from "create-util/Create.sol";

/**
 * @dev Error that occurs when deploying a contract has failed.
 * @param emitter The contract that emits the error.
 */
error DeploymentFailed(address emitter);

/**
 * @dev The interface of this cheat code is called `_CheatCodes`,
 * so you can use the `CheatCodes` interface (see here:
 * https://book.getfoundry.sh/cheatcodes/?highlight=CheatCodes#cheatcode-types)
 * in other test files without errors.
 */
// solhint-disable-next-line contract-name-camelcase
interface _CheatCodes {
    function ffi(string[] calldata) external returns (bytes memory);
}

/**
 * @title Vyper Contract Deployer
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/0xKitsune/Foundry-Vyper/blob/main/lib/utils/VyperDeployer.sol.
 * @dev The Vyper Contract Deployer is a pre-built contract containing functions that
 * use a path, a filename, any ABI-encoded constructor arguments, and optionally the
 * target EVM version, and deploy the corresponding Vyper contract, returning the address
 * that the bytecode was deployed to.
 */
contract VyperDeployer is Create {
    address private constant HEVM_ADDRESS =
        address(uint160(uint256(keccak256("hevm cheat code"))));
    address private self = address(this);

    /**
     * @dev Initialises `cheatCodes` in order to use the foreign function interface (ffi)
     * to compile the Vyper contracts.
     */
    _CheatCodes private cheatCodes = _CheatCodes(HEVM_ADDRESS);

    /**
     * @dev Compiles a Vyper contract and returns the address that the contract
     * was deployed to. If the deployment fails, an error is thrown.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(
        string calldata path,
        string calldata fileName
    ) public returns (address deployedAddress) {
        /**
         * @dev Create a list of strings with the commands necessary
         * to compile Vyper contracts.
         */
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper";
        cmds[1] = string.concat(path, fileName, ".vy");

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = cheatCodes.ffi(cmds);

        /**
         * @dev Deploy the bytecode with the `CREATE` instruction.
         */
        deployedAddress = deploy({amount: 0, bytecode: bytecode});

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0))
            revert DeploymentFailed({emitter: self});
    }

    /**
     * @dev Compiles a Vyper contract with constructor arguments and returns the
     * address that the contract was deployed to. If the deployment fails, an error
     * is thrown.
     * @notice Function overload of `deployContract` that allows any ABI-encoded
     * constructor arguments to be passed.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @param args The ABI-encoded constructor arguments.
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(
        string calldata path,
        string calldata fileName,
        bytes calldata args
    ) public returns (address deployedAddress) {
        /**
         * @dev Create a list of strings with the commands necessary
         * to compile Vyper contracts.
         */
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper";
        cmds[1] = string.concat(path, fileName, ".vy");

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = cheatCodes.ffi(cmds);

        /**
         * @dev Add the ABI-encoded constructor arguments to the
         * deployment bytecode.
         */
        bytecode = abi.encodePacked(bytecode, args);

        /**
         * @dev Deploy the bytecode with the `CREATE` instruction.
         */
        deployedAddress = deploy({amount: 0, bytecode: bytecode});

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0))
            revert DeploymentFailed({emitter: self});
    }

    /**
     * @dev Compiles a Vyper contract and returns the address that the contract
     * was deployed to. If the deployment fails, an error is thrown.
     * @notice Function overload of `deployContract` that allows the configuration
     * of the target EVM version.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @param evmVersion The EVM version used for compilation.
     * For example, the EVM version for the Paris hard fork is "paris".
     * You can retrieve all available Vyper EVM versions by invoking `vyper -h`.
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(
        string calldata path,
        string calldata fileName,
        string calldata evmVersion,
        bool /*overloadPlaceholder*/
    ) public returns (address deployedAddress) {
        /**
         * @dev Create a list of strings with the commands necessary
         * to compile Vyper contracts.
         */
        string[] memory cmds = new string[](4);
        cmds[0] = "vyper";
        cmds[1] = string.concat(path, fileName, ".vy");
        cmds[2] = "--evm-version";
        cmds[3] = evmVersion;

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = cheatCodes.ffi(cmds);

        /**
         * @dev Deploy the bytecode with the `CREATE` instruction.
         */
        deployedAddress = deploy({amount: 0, bytecode: bytecode});

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0))
            revert DeploymentFailed({emitter: self});
    }

    /**
     * @dev Compiles a Vyper contract with constructor arguments and returns the
     * address that the contract was deployed to. If the deployment fails, an error
     * is thrown.
     * @notice Function overload of `deployContract`, which allows the passing of
     * any ABI-encoded constructor arguments and enables the configuration of the
     * target EVM version.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @param args The ABI-encoded constructor arguments.
     * @param evmVersion The EVM version used for compilation.
     * For example, the EVM version for the Paris hard fork is "paris".
     * You can retrieve all available Vyper EVM versions by invoking `vyper -h`.
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(
        string calldata path,
        string calldata fileName,
        bytes calldata args,
        string calldata evmVersion,
        bool /*overloadPlaceholder*/
    ) public returns (address deployedAddress) {
        /**
         * @dev Create a list of strings with the commands necessary
         * to compile Vyper contracts.
         */
        string[] memory cmds = new string[](4);
        cmds[0] = "vyper";
        cmds[1] = string.concat(path, fileName, ".vy");
        cmds[2] = "--evm-version";
        cmds[3] = evmVersion;

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = cheatCodes.ffi(cmds);

        /**
         * @dev Add the ABI-encoded constructor arguments to the
         * deployment bytecode.
         */
        bytecode = abi.encodePacked(bytecode, args);

        /**
         * @dev Deploy the bytecode with the `CREATE` instruction.
         */
        deployedAddress = deploy({amount: 0, bytecode: bytecode});

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0))
            revert DeploymentFailed({emitter: self});
    }
}
