// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface IMulticall {
    struct Batch {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct BatchValue {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct BatchSelf {
        bool allowFailure;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function multicall(
        Batch[] calldata batch
    ) external returns (Result[] memory results);

    function multicall_value(
        BatchValue[] calldata batchValue
    ) external payable returns (Result[] memory results);

    function multicall_self(
        BatchSelf[] calldata batchSelf
    ) external returns (Result[] memory results);

    function multistaticcall(
        Batch[] calldata batch
    ) external pure returns (Result[] memory results);
}
