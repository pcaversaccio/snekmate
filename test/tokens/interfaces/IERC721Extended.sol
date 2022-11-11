// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {IERC721Metadata} from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC4494} from "./IERC4494.sol";

interface IERC721Extended is IERC721Metadata, IERC721Enumerable, IERC4494 {
    function burn(uint256 tokenId) external;

    function owner() external view returns (address);

    function is_minter(address minter) external view returns (bool);

    function safe_mint(address owner, string calldata uri) external;

    function set_minter(address minter, bool status) external;

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
