// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.28;

interface IECDSA {
    function recover_sig(
        bytes32 hash,
        bytes calldata signature
    ) external pure returns (address);
}
