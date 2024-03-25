// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";

interface IAccessControlExtended is IERC165, IAccessControl {
    function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

    function MINTER_ROLE() external pure returns (bytes32);

    function PAUSER_ROLE() external pure returns (bytes32);

    function set_role_admin(bytes32 role, bytes32 adminRole) external;
}
