// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title EtherReceiver
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/mds1/multicall/blob/main/src/test/mocks/EtherSink.sol.
 * @dev Allows to test receiving ether via low-level calls.
 */
contract EtherReceiver {
    receive() external payable {}
}
