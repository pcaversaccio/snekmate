// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface IOwnable {
    function owner() external view returns (address);

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
