// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.23;

import {IERC721Receiver} from "openzeppelin/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";

interface ITimelockController is
    IERC721Receiver,
    IERC1155Receiver,
    IAccessControl
{
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 amount,
        bytes payload,
        bytes32 predecessor,
        uint256 delay
    );

    event CallExecuted(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 amount,
        bytes payload
    );

    event CallSalt(bytes32 indexed id, bytes32 salt);

    event Cancelled(bytes32 indexed id);

    event MinimumDelayChange(uint256 oldDuration, uint256 newDuration);

    function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

    function PROPOSER_ROLE() external pure returns (bytes32);

    function EXECUTOR_ROLE() external pure returns (bytes32);

    function CANCELLER_ROLE() external pure returns (bytes32);

    function IERC721_TOKENRECEIVER_SELECTOR() external pure returns (bytes4);

    function IERC1155_TOKENRECEIVER_SINGLE_SELECTOR()
        external
        pure
        returns (bytes4);

    function IERC1155_TOKENRECEIVER_BATCH_SELECTOR()
        external
        pure
        returns (bytes4);

    function get_timestamp(bytes32 id) external view returns (uint256);

    function get_minimum_delay() external view returns (uint256);

    function is_operation(bytes32 id) external view returns (bool);

    function is_operation_pending(bytes32 id) external view returns (bool);

    function is_operation_ready(bytes32 id) external view returns (bool);

    function is_operation_done(bytes32 id) external view returns (bool);

    /**
     * @dev As Enums are handled differently in Vyper and Solidity, we return
     * the directly underlying Vyper type `uint256` (instead of `OperationState`)
     * for Enums for ease of testing.
     */
    function get_operation_state(bytes32 id) external view returns (uint256);

    function hash_operation(
        address target,
        uint256 amount,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash);

    function hash_operation_batch(
        address[] calldata targets,
        uint256[] calldata amounts,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash);

    function schedule(
        address target,
        uint256 amount,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external;

    function schedule_batch(
        address[] calldata targets,
        uint256[] calldata amounts,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external;

    function cancel(bytes32 id) external;

    function execute(
        address target,
        uint256 amount,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;

    function execute_batch(
        address[] calldata targets,
        uint256[] calldata amounts,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;

    function update_delay(uint256 newDelay) external;

    function set_role_admin(bytes32 role, bytes32 adminRole) external;
}
