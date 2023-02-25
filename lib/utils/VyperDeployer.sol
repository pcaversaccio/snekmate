// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.19;

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
 * @dev The Vyper deployer is a pre-built contract that takes a filename
 * and deploys the corresponding Vyper contract, returning the address
 * that the bytecode was deployed to.
 */
contract VyperDeployer is Create {
    address private constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
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
        string memory path,
        string memory fileName
    ) public returns (address) {
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
        address deployedAddress;
        deployedAddress = deploy(0, bytecode);

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0)) revert DeploymentFailed(self);

        /**
         * @dev Return the address that the contract was deployed to.
         */
        return deployedAddress;
    }

    /**
     * @dev Compiles a Vyper contract with constructor arguments and
     * returns the address that the contract was deployed to. If the
     * deployment fails, an error is thrown.
     * @param path The directory path of the Vyper contract.
     * For example, the path of "utils" is "src/utils/".
     * @param fileName The file name of the Vyper contract.
     * For example, the file name for "ECDSA.vy" is "ECDSA".
     * @param args The ABI-encoded constructor arguments.
     * @return deployedAddress The address that the contract was deployed to.
     */
    function deployContract(
        string memory path,
        string memory fileName,
        bytes calldata args
    ) public returns (address) {
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
        bytes memory _bytecode = cheatCodes.ffi(cmds);

        /**
         * @dev Add the ABI-encoded constructor arguments to the
         * deployment bytecode.
         */
        bytes memory bytecode = abi.encodePacked(_bytecode, args);

        /**
         * @dev Deploy the bytecode with the `CREATE` instruction.
         */
        address deployedAddress;
        deployedAddress = deploy(0, bytecode);

        /**
         * @dev Check that the deployment was successful.
         */
        if (deployedAddress == address(0)) revert DeploymentFailed(self);

        /**
         * @dev Return the address that the contract was deployed to.
         */
        return deployedAddress;
    }
}
