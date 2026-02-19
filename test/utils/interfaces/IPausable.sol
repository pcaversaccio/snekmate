// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.34;

interface IPausable {
    event Paused(address account);

    event Unpaused(address account);

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;
}
