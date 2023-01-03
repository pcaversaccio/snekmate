// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IBase64} from "./interfaces/IBase64.sol";

contract Base64Test is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBase64 private base64;

    function setUp() public {
        base64 = IBase64(vyperDeployer.deployContract("src/utils/", "Base64"));
    }

    function testBase64EncodeEmptyString() public {
        string[] memory output = base64.encode("", false);
    }
}
