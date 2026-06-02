// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.35;

interface ICircuitBreaker {
    event BreakerTripped(address account);

    function breaker_tripped() external view returns (bool);

    function trip() external;
}
