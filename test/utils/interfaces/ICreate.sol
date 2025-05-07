// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

interface ICreate {
    function deploy_create(bytes calldata initCode) external returns (address);

    function compute_create_address_self(uint256 nonce) external view returns (address);

    function compute_create_address(address deployer, uint256 nonce) external view returns (address);
}
