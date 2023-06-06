// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.20;

interface IEIP712DomainSeparator {
    function domain_separator_v4() external view returns (bytes32);

    function hash_typed_data_v4(
        bytes32 structHash
    ) external view returns (bytes32);

    function eip712Domain()
        external
        view
        returns (
            bytes1,
            string calldata,
            string calldata,
            uint256,
            address,
            bytes32,
            uint256[] calldata
        );
}
