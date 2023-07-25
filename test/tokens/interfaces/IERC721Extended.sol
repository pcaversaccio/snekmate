// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC5267} from "openzeppelin/interfaces/IERC5267.sol";
import {IERC4494} from "./IERC4494.sol";

interface IERC721Extended is
    IERC721Metadata,
    IERC721Enumerable,
    IERC4494,
    IERC5267
{
    function burn(uint256 tokenId) external;

    function is_minter(address minter) external view returns (bool);

    function safe_mint(address owner, string calldata uri) external;

    function set_minter(address minter, bool status) external;

    function owner() external view returns (address);

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
