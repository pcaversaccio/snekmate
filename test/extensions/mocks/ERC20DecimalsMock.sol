// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ERC20DecimalsMock
 * @author pcaversaccio
 * @dev Allows to mock a decimal return value greater than the maximum value
 * of the type `uint8`.
 */
contract ERC20DecimalsMock {
    /**
     * @dev Mocks a decimal return value greater than the maximum value of the
     * type `uint8`.
     * @return uint256 The number of decimals used to get its user representation.
     */
    function decimals() public pure returns (uint256) {
        return type(uint256).max;
    }
}
