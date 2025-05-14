// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import {Create} from "create-util/Create.sol";
import {console, StdStyle} from "forge-std/Test.sol";

/**
 * @dev Error that occurs when compiling a contract has failed.
 * @param emitter The contract that emits the error.
 */
error CompilationFailed(address emitter);

/**
 * @dev Error that occurs when deploying a contract has failed.
 * @param emitter The contract that emits the error.
 */
error DeploymentFailed(address emitter);

/**
 * @dev The interface of this cheat code is called `_VmSafe`, so you
 * can use the `VmSafe` interface (see here: https://book.getfoundry.sh/cheatcodes)
 * in other test files without errors.
 */
// solhint-disable-next-line contract-name-capwords
interface _VmSafe {
    /**
     * @dev Performs a foreign function call via the terminal.
     */
    function ffi(string[] calldata commandInput) external returns (bytes memory result);
}

/**
 * @title Vyper Contract Deployer
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/0xKitsune/Foundry-Vyper/blob/main/lib/utils/VyperDeployer.sol.
 * @dev The Vyper Contract Deployer is a pre-built contract containing functions that
 * use a path, a filename, any ABI-encoded constructor arguments, and optionally the
 * target EVM version and the compiler optimisation mode, and deploy the corresponding
 * Vyper contract, returning the address that the bytecode was deployed to.
 */
contract VyperDeployer is Create {
    address private constant HEVM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    address private self = address(this);

    /**
     * @dev Initialises `vmSafe` in order to use the foreign function interface (ffi)
     * to compile the Vyper contracts.
     */
    _VmSafe private vmSafe = _VmSafe(HEVM_ADDRESS);

    /**
     * @dev Compiles a Vyper contract and returns the address that the contract
     * was deployed to. If the deployment fails, an error is thrown.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(string calldata path, string calldata fileName) public returns (address deployedAddress) {
        /**
         * @dev Create a list of strings with the commands necessary
         * to compile Vyper contracts.
         */
        string[] memory cmds = new string[](3);
        cmds[0] = "python";
        cmds[1] = "lib/utils/compile.py";
        cmds[2] = string.concat(path, fileName, ".vy");

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = vmSafe.ffi(cmds);

        /**
         * @dev Revert if the Vyper compilation failed or is a zero-length
         * contract creation bytecode.
         */
        if (bytecode.length == 0) {
            // solhint-disable-next-line no-console
            console.log(
                StdStyle.red("Vyper compilation failed! Please ensure that you have a valid Vyper version installed.")
            );
            revert CompilationFailed({emitter: self});
        }

        /**
         * @dev Deploy the bytecode with the `CREATE` instruction.
         */
        deployedAddress = deploy({amount: 0, bytecode: bytecode});

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0)) revert DeploymentFailed({emitter: self});
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
        string[] memory cmds = new string[](3);
        cmds[0] = "python";
        cmds[1] = "lib/utils/compile.py";
        cmds[2] = string.concat(path, fileName, ".vy");

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = vmSafe.ffi(cmds);

        /**
         * @dev Revert if the Vyper compilation failed or is a zero-length
         * contract creation bytecode.
         */
        if (bytecode.length == 0) {
            // solhint-disable-next-line no-console
            console.log(
                StdStyle.red("Vyper compilation failed! Please ensure that you have a valid Vyper version installed.")
            );
            revert CompilationFailed({emitter: self});
        }

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
        if (deployedAddress == address(0)) revert DeploymentFailed({emitter: self});
    }

    /**
     * @dev Compiles a Vyper contract and returns the address that the contract
     * was deployed to. If the deployment fails, an error is thrown.
     * @notice Function overload of `deployContract` that allows the configuration
     * of the target EVM version and the compiler optimisation mode.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @param evmVersion The EVM version used for compilation.
     * For example, the EVM version for the Cancun-Deneb hard fork is "cancun".
     * You can retrieve all available Vyper EVM versions by invoking `vyper -h`.
     * @param optimiserMode The optimisation mode used for compilation.
     * For example, the default optimisation mode since Vyper `0.3.10` is "gas".
     * You can retrieve all available Vyper optimisation modes by invoking `vyper -h`.
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(
        string calldata path,
        string calldata fileName,
        string calldata evmVersion,
        string calldata optimiserMode
    ) public returns (address deployedAddress) {
        /**
         * @dev Create a list of strings with the commands necessary
         * to compile Vyper contracts.
         */
        string[] memory cmds = new string[](7);
        cmds[0] = "python";
        cmds[1] = "lib/utils/compile.py";
        cmds[2] = string.concat(path, fileName, ".vy");
        cmds[3] = "--evm-version";
        cmds[4] = evmVersion;
        cmds[5] = "--optimize";
        cmds[6] = optimiserMode;

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = vmSafe.ffi(cmds);

        /**
         * @dev Revert if the Vyper compilation failed or is a zero-length
         * contract creation bytecode.
         */
        if (bytecode.length == 0) {
            // solhint-disable-next-line no-console
            console.log(
                StdStyle.red("Vyper compilation failed! Please ensure that you have a valid Vyper version installed.")
            );
            revert CompilationFailed({emitter: self});
        }

        /**
         * @dev Deploy the bytecode with the `CREATE` instruction.
         */
        deployedAddress = deploy({amount: 0, bytecode: bytecode});

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0)) revert DeploymentFailed({emitter: self});
    }

    /**
     * @dev Compiles a Vyper contract with constructor arguments and returns the
     * address that the contract was deployed to. If the deployment fails, an error
     * is thrown.
     * @notice Function overload of `deployContract`, which allows the passing of
     * any ABI-encoded constructor arguments and enables the configuration of the
     * target EVM version and the compiler optimisation mode.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @param args The ABI-encoded constructor arguments.
     * @param evmVersion The EVM version used for compilation.
     * For example, the EVM version for the Cancun-Deneb hard fork is "cancun".
     * You can retrieve all available Vyper EVM versions by invoking `vyper -h`.
     * @param optimiserMode The optimisation mode used for compilation.
     * For example, the default optimisation mode since Vyper `0.3.10` is "gas".
     * You can retrieve all available Vyper optimisation modes by invoking `vyper -h`.
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(
        string calldata path,
        string calldata fileName,
        bytes calldata args,
        string calldata evmVersion,
        string calldata optimiserMode
    ) public returns (address deployedAddress) {
        /**
         * @dev Create a list of strings with the commands necessary
         * to compile Vyper contracts.
         */
        string[] memory cmds = new string[](7);
        cmds[0] = "python";
        cmds[1] = "lib/utils/compile.py";
        cmds[2] = string.concat(path, fileName, ".vy");
        cmds[3] = "--evm-version";
        cmds[4] = evmVersion;
        cmds[5] = "--optimize";
        cmds[6] = optimiserMode;

        /**
         * @dev Compile the Vyper contract and return the bytecode.
         */
        bytes memory bytecode = vmSafe.ffi(cmds);

        /**
         * @dev Revert if the Vyper compilation failed or is a zero-length
         * contract creation bytecode.
         */
        if (bytecode.length == 0) {
            // solhint-disable-next-line no-console
            console.log(
                StdStyle.red("Vyper compilation failed! Please ensure that you have a valid Vyper version installed.")
            );
            revert CompilationFailed({emitter: self});
        }

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
        if (deployedAddress == address(0)) revert DeploymentFailed({emitter: self});
    }
}
