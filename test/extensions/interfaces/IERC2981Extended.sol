// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";

interface IERC2981Extended is IERC2981 {
    function set_default_royalty(
        address receiver,
        uint96 feeNumerator
    ) external;

    function delete_default_royalty() external;

    function set_token_royalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external;

    function reset_token_royalty(uint256 tokenId) external;

    function owner() external view returns (address);

    function transfer_ownership(address newOwner) external;

    function renounce_ownership() external;
}
