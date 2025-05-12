// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

interface ICreate2 {
    function deploy_create2(bytes32 salt, bytes calldata initCode) external payable returns (address);

    function compute_create2_address_self(bytes32 salt, bytes32 bytecodeHash) external view returns (address);

    function compute_create2_address(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) external view returns (address);
}
