// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.34;

import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC5267} from "openzeppelin/interfaces/IERC5267.sol";
import {IERC4906} from "openzeppelin/interfaces/IERC4906.sol";
import {IERC4494} from "./IERC4494.sol";

interface IERC721Extended is IERC721Metadata, IERC721Enumerable, IERC4494, IERC5267, IERC4906 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event RoleMinterChanged(address indexed minter, bool status);

    function burn(uint256 tokenId) external;

    function is_minter(address minter) external view returns (bool);

    function safe_mint(address owner, string calldata uri) external;

    function _customMint(address owner, uint256 amount) external;

    function set_minter(address minter, bool status) external;

    function owner() external view returns (address);

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
