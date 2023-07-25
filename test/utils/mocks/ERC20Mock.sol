// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mock
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/token/ERC20Mock.sol.
 * @dev Allows to mock a simple ERC-20 implementation.
 */
contract ERC20Mock is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        address initialAccount_,
        uint256 initialBalance_
    ) payable ERC20(name_, symbol_) {
        _mint(initialAccount_, initialBalance_);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`.
     * @param account The 20-byte account address.
     * @param amount The 32-byte token amount to be created.
     */
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.
     * @param account The 20-byte account address.
     * @param amount The 32-byte token amount to be destroyed.
     */
    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
