// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.31;

interface IBlockHash {
    function block_hash(uint256 blockNumber) external view returns (bytes32);
}
