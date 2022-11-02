// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

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

    struct BatchValueSelf {
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function multicall(
        Batch[] memory batch
    ) external returns (Result[] memory results);

    function multicall_value(
        BatchValue[] memory batchValue
    ) external payable returns (Result[] memory results);

    function multicall_self(
        BatchSelf[] memory batchSelf
    ) external returns (Result[] memory results);

    function multicall_value_self(
        BatchValueSelf[] memory batchValueSelf
    ) external payable returns (Result[] memory results);

    function multistaticcall(
        Batch[] memory batch
    ) external pure returns (Result[] memory results);
}
