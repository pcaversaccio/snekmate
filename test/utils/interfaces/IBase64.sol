// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

interface IBase64 {
    function encode(
        bytes calldata data,
        bool base64Url
    ) external pure returns (string[] memory);

    function decode(
        string calldata data,
        bool base64Url
    ) external pure returns (bytes[] memory);
}
