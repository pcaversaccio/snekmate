// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {IERC20Metadata} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20Extended is IERC20Metadata {
    function owner() external view returns (address);

    function is_minter(address minter) external view returns (bool);

    function nonces(address owner) external view returns (uint256);

    function increase_allowance(address spender, uint256 addedAmount)
        external
        returns (bool);

    function decrease_allowance(address spender, uint256 subtractedAmount)
        external
        returns (bool);

    function burn(uint256 amount) external;

    function burn_from(address owner, uint256 amount) external;

    function mint(address owner, uint256 amount) external;

    function set_minter(address minter, bool status) external;

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint256 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
