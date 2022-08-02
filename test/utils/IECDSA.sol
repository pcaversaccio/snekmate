// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IECDSA {
    function _recover_sig(bytes32 hash, bytes memory signature)
        external
        pure
        returns (address);
}
