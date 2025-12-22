// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.33;

interface IEIP7702Utils {
    function fetch_delegate(address account) external view returns (address);
}
