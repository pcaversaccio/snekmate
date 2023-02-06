// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.18;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";

interface IAccessControlExtended is IERC165, IAccessControl {
    function set_role_admin(bytes32 role, bytes32 adminRole) external;
}
