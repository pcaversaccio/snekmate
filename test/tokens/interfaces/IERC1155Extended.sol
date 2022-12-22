// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {IERC1155MetadataURI} from "openzeppelin/token/ERC1155/extensions/IERC1155MetadataURI.sol";

interface IERC1155Extended is IERC1155MetadataURI {
    function is_minter(address account) external view returns (bool);
    function safe_mint(address owner, uint256 id, uint256 amount, bytes calldata data) external;
    function set_minter(address minter, bool status) external;
    function owner() external view returns (address);
    function transfer_ownership(address new_owner) external;
    function renounce_ownership() external; 
}
