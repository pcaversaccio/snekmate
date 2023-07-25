// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

interface IERC4494 is IERC165 {
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(uint256 tokenId) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
