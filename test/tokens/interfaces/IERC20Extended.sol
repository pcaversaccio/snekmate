// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "openzeppelin/interfaces/IERC5267.sol";

interface IERC20Extended is IERC20Metadata, IERC20Permit, IERC5267 {
    function burn(uint256 amount) external;

    function burn_from(address owner, uint256 amount) external;

    function is_minter(address minter) external view returns (bool);

    function mint(address owner, uint256 amount) external;

    function set_minter(address minter, bool status) external;

    function owner() external view returns (address);

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
