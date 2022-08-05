// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.15;

interface IEIP712 {
    function domain_separator_v4() external view returns (bytes32);

    function hash_typed_data_v4(bytes32 struct_hash)
        external
        view
        returns (bytes32);
}
