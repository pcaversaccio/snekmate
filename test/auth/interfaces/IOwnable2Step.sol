// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface IOwnable2Step {
    function owner() external view returns (address);

    function pending_owner() external view returns (address);

    function transfer_ownership(address newOwner) external;

    function accept_ownership() external;

    function renounce_ownership() external;
}
