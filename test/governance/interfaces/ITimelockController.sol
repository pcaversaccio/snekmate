// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.23;

interface ITimelockController {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function EXECUTOR_ROLE() external view returns (bytes32);
    function PROPOSER_ROLE() external view returns (bytes32);
    function TIMELOCK_ADMIN_ROLE() external view returns (bytes32);
    function cancel(bytes32 id) external;
    function execute(
        address target,
        uint256 value,
        bytes memory data,
        bytes32 predecessor,
        bytes32 salt
    ) external;
    function execute_batch(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory datas,
        bytes32 predecessor,
        bytes32 salt
    ) external;
    function get_minimum_delay() external view returns (uint256 duration);
    function get_timestamp(
        bytes32 id
    ) external view returns (uint256 timestamp);
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);
    function hash_operation(
        address target,
        uint256 value,
        bytes memory data,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash);
    function hash_operation_batch(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory datas,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash);
    function is_operation(bytes32 id) external view returns (bool pending);
    function is_operation_done(bytes32 id) external view returns (bool done);
    function is_operation_pending(
        bytes32 id
    ) external view returns (bool pending);
    function is_operation_ready(bytes32 id) external view returns (bool ready);
    function schedule(
        address target,
        uint256 value,
        bytes memory data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external;
    function schedule_batch(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external;
    function update_delay(uint256 newDelay) external;
}
