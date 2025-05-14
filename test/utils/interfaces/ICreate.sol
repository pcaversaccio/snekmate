// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

interface ICreate {
    function deploy_create(bytes calldata initCode) external payable returns (address);

    function compute_create_address_self(uint256 nonce) external view returns (address);

    function compute_create_address(address deployer, uint256 nonce) external pure returns (address);
}
