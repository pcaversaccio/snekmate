// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {IERC5267} from "openzeppelin/interfaces/IERC5267.sol";

interface IEIP712DomainSeparator is IERC5267 {
    function domain_separator_v4() external view returns (bytes32);

    function hash_typed_data_v4(
        bytes32 structHash
    ) external view returns (bytes32);
}
