// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.31;

interface ICreate3 {
    function deploy_create3(bytes32 salt, bytes calldata initCode) external payable returns (address);

    function compute_create3_address_self(bytes32 salt) external view returns (address);

    function compute_create3_address(bytes32 salt, address deployer) external pure returns (address);
}
