// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

interface IBase64 {
    function encode(
        bytes memory data,
        bool base64Url
    ) external pure returns (string[] memory);

    function decode(
        string memory data,
        bool base64Url
    ) external pure returns (bytes[] memory);
}
