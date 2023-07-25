// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface ICreateAddress {
    function compute_address_rlp_self(
        uint256 nonce
    ) external view returns (address);

    function compute_address_rlp(
        address deployer,
        uint256 nonce
    ) external view returns (address);
}
