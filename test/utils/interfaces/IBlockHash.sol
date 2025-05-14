// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

interface IBlockHash {
    function block_hash(uint256 blockNumber) external view returns (bytes32);
}
