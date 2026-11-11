// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.38;

interface IPausable {
    event Paused(address account);

    event Unpaused(address account);

    error PausableEnforcedPause();

    error PausableExpectedPause();

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;
}
