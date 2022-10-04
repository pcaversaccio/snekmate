// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IBatchDistributor {
    struct Transaction {
        address recipient;
        uint256 amount;
    }

    struct Batch {
        Transaction[] txns;
    }

    function distribute_ether(Batch memory batch) external payable;

    function distribute_token(IERC20 token, Batch memory batch) external;
}
