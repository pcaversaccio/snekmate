// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.20;

import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {IERC4626} from "openzeppelin/interfaces/IERC4626.sol";
import {IERC5267} from "openzeppelin/interfaces/IERC5267.sol";

interface IERC4626Extended is IERC20Metadata, IERC20Permit, IERC4626, IERC5267 {
    function increase_allowance(
        address spender,
        uint256 addedAmount
    ) external returns (bool);

    function decrease_allowance(
        address spender,
        uint256 subtractedAmount
    ) external returns (bool);
}
