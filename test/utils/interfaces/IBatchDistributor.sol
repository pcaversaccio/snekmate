// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface IBatchDistributor {
    struct Transaction {
        address recipient;
        uint256 amount;
    }

    struct Batch {
        Transaction[] txns;
    }

    function distribute_ether(Batch calldata batch) external payable;

    function distribute_token(IERC20 token, Batch calldata batch) external;
}
