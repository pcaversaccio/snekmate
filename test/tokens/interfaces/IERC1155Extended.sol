// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {IERC1155MetadataURI} from "openzeppelin/token/ERC1155/extensions/IERC1155MetadataURI.sol";

interface IERC1155Extended is IERC1155MetadataURI {
    function burn(address owner, uint256 id, uint256 amount) external;

    function burn_batch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function exists(uint256 id) external view returns (bool);

    function is_minter(address account) external view returns (bool);

    function owner() external view returns (address);

    function renounce_ownership() external;

    function safe_mint(
        address owner,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safe_mint_batch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function set_minter(address minter, bool status) external;

    function set_uri(uint256 id, string memory tokenUri) external;

    function total_supply(uint256 id) external view returns (uint256);

    function transfer_ownership(address newOwner) external;
}
