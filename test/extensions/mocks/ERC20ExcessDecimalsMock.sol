// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title ERC20ExcessDecimalsMock
 * @author pcaversaccio
 * @dev Allows to mock a `decimals` return value greater than the maximum value
 * of the type `uint8`.
 */
contract ERC20ExcessDecimalsMock {
    /**
     * @dev Mocks a `decimals` return value greater than the maximum value of the
     * type `uint8`.
     * @return uint256 The number of `decimals` used to get its user representation.
     */
    function decimals() public pure returns (uint256) {
        return type(uint256).max;
    }
}
