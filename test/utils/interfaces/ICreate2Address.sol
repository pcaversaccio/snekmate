// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface ICreate2Address {
    function compute_address_self(
        bytes32 salt,
        bytes32 bytecodeHash
    ) external view returns (address);

    function compute_address(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) external view returns (address);
}
