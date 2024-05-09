// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IBatchDistributor} from "../interfaces/IBatchDistributor.sol";
import {ERC20Mock} from "./ERC20Mock.sol";

/**
 * @title DistributeEtherReentrancyMock
 * @author pcaversaccio
 * @dev Allows to mock a single-function reentrancy via the function `distribute_ether`
 * in `BatchDistributor`.
 */
contract DistributeEtherReentrancyMock {
    address private constant _FUND_RECEIVER = address(1_337);
    uint256 private _counter;

    /**
     * @dev Reenters the function `distribute_ether` in `BatchDistributor` once.
     */
    // solhint-disable-next-line no-complex-fallback
    receive() external payable {
        if (_counter == 0) {
            IBatchDistributor.Transaction[]
                memory transaction = new IBatchDistributor.Transaction[](1);
            transaction[0] = IBatchDistributor.Transaction({
                recipient: _FUND_RECEIVER,
                amount: msg.value
            });
            IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
                txns: transaction
            });

            // solhint-disable-next-line avoid-low-level-calls
            (bool reentered, ) = msg.sender.call{value: msg.value}(
                abi.encodeWithSelector(
                    IBatchDistributor.distribute_ether.selector,
                    batch
                )
            );
            if (!reentered) {
                // solhint-disable-next-line reason-string, gas-custom-errors
                revert(
                    "DistributeEtherReentrancyMock: reentrancy unsuccessful"
                );
            }
            _counter = 1;
        }
    }
}

/**
 * @title DistributeTokenReentrancyMock
 * @author pcaversaccio
 * @dev Allows to mock a cross-function reentrancy via the functions `distribute_ether`
 * and `distribute_token` in `BatchDistributor`.
 */
contract DistributeTokenReentrancyMock {
    address private constant _FUND_RECEIVER = address(1_337);
    uint256 private _counter;

    /**
     * @dev Reenters the function `distribute_token` in `BatchDistributor` once.
     */
    // solhint-disable-next-line no-complex-fallback
    receive() external payable {
        if (_counter == 0) {
            string memory arg1 = "MyToken";
            string memory arg2 = "MTKN";
            address arg3 = address(this);
            uint256 arg4 = 100;
            ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
            erc20Mock.approve(msg.sender, arg4);

            IBatchDistributor.Transaction[]
                memory transaction = new IBatchDistributor.Transaction[](1);
            transaction[0] = IBatchDistributor.Transaction({
                recipient: _FUND_RECEIVER,
                amount: 30
            });
            IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
                txns: transaction
            });

            // solhint-disable-next-line avoid-low-level-calls
            (bool reentered, ) = msg.sender.call(
                abi.encodeWithSelector(
                    IBatchDistributor.distribute_token.selector,
                    erc20Mock,
                    batch
                )
            );
            if (!reentered) {
                // solhint-disable-next-line reason-string, gas-custom-errors
                revert(
                    "DistributeTokenReentrancyMock: reentrancy unsuccessful"
                );
            }
            _counter = 1;
        }
    }
}
