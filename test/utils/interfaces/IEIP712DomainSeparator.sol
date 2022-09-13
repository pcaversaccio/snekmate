// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

interface IEIP712DomainSeparator {
    function domain_separator_v4() external view returns (bytes32);

    function hash_typed_data_v4(bytes32 structHash)
        external
        view
        returns (bytes32);
}
