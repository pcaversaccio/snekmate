// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @dev Error that occurs when a method reverts.
 * @param emitter The contract that emits the error.
 */
error Reverted(address emitter);

/**
 * @title MockCallee
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/mds1/multicall/blob/main/src/test/mocks/MockCallee.sol.
 * @dev Receives calls from the multicaller.
 */
contract MockCallee {
    uint256 public number;
    address private self = address(this);

    /**
     * @dev Stores a uint256 value in the variable `number`.
     * @param num The uint256 value to store.
     * @return bool A Boolean variable indicating success or failure.
     */
    function store(uint256 num) public returns (bool) {
        number = num;
        return true;
    }

    /**
     * @dev Returns the block hash for the given block number.
     * @param blockNumber The block number.
     * @return blockHash The 32-byte block hash.
     */
    function getBlockHash(
        uint256 blockNumber
    ) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /**
     * @dev A function that simply reverts.
     */
    function thisMethodReverts() public view {
        revert Reverted(self);
    }

    /**
     * @dev A transfer function that accepts a `msg.value`.
     * @param target The destination address of the ether transfer.
     */
    function transferEther(address target) public payable {
        // solhint-disable-next-line avoid-low-level-calls
        (bool ok, ) = target.call{value: msg.value}("");
        if (!ok) revert Reverted(self);
    }
}
