// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Create2} from "openzeppelin/utils/Create2.sol";

/**
 * @title Create2Impl
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a81b0d0b2136a0cca6029048be25c4e2bb230d49/contracts/mocks/Create2Impl.sol.
 * @dev Allows to test `CREATE2` deployments and address computation.
 */
contract Create2Impl {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via `computeAddress`.
     * @param value The 32-byte ether value used to create the contract address.
     * @param salt The 32-byte random value used to create the contract address.
     * @param code The contract creation bytecode used to create the contract address.
     */
    function deploy(uint256 value, bytes32 salt, bytes memory code) public {
        Create2.deploy(value, salt, code);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via
     * this contract using the `CREATE2` opcode. Any change in the `codeHash` or
     * `salt` values will result in a new destination address.
     * @param salt The 32-byte random value used to create the contract address.
     * @param codeHash The 32-byte bytecode digest of the contract creation bytecode.
     * @return address The 20-byte address where a contract will be stored.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 codeHash
    ) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via
     * `deployer` using the `CREATE2` opcode. Any change in the `codeHash` or
     * `salt` values will result in a new destination address.
     * @param salt The 32-byte random value used to create the contract address.
     * @param codeHash The 32-byte bytecode digest of the contract creation bytecode.
     * @param deployer The 20-byte deployer address.
     * @return address The 20-byte address where a contract will be stored.
     */
    function computeAddressWithDeployer(
        bytes32 salt,
        bytes32 codeHash,
        address deployer
    ) public pure returns (address) {
        return Create2.computeAddress(salt, codeHash, deployer);
    }

    receive() external payable {}
}
