// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.36;

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    function owner() external view returns (address);

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
