// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {PRBTest} from "prb/test/PRBTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IBase64} from "./interfaces/IBase64.sol";

/**
 * @dev We make use of Paul's testing assertions (https://github.com/paulrberg/prb-test)
 * in this test suite since it supports equality assertions for arrays.
 */
contract Base64Test is PRBTest {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBase64 private base64;

    function setUp() public {
        base64 = IBase64(vyperDeployer.deployContract("src/utils/", "Base64"));
    }

    function testEncodeEmptyString() public {
        string[] memory emptyArray = new string[](0);
        string[] memory outputStd = base64.encode("", false);
        string[] memory outputUrl = base64.encode("", true);
        assertEq(outputStd, emptyArray);
        assertEq(outputUrl, emptyArray);
    }

    function testEncodeWithNoPadding() public {
        string memory data = "test12";
        string[] memory encoded = new string[](2);
        encoded[0] = "dGVz";
        encoded[1] = "dDEy";
        string[] memory outputStd = base64.encode(bytes(data), false);
        string[] memory outputUrl = base64.encode(bytes(data), true);
        assertEq(outputStd, encoded);
        assertEq(outputUrl, encoded);
    }

    function testEncodeWithSinglePadding() public {
        string memory data = "test1";
        string[] memory encoded = new string[](2);
        encoded[0] = "dGVz";
        encoded[1] = "dDE=";
        string[] memory outputStd = base64.encode(bytes(data), false);
        string[] memory outputUrl = base64.encode(bytes(data), true);
        assertEq(outputStd, encoded);
        assertEq(outputUrl, encoded);
    }

    function testEncodeWithDoublePadding() public {
        string memory data = "test";
        string[] memory encoded = new string[](2);
        encoded[0] = "dGVz";
        encoded[1] = "dA==";
        string[] memory outputStd = base64.encode(bytes(data), false);
        string[] memory outputUrl = base64.encode(bytes(data), true);
        assertEq(outputStd, encoded);
        assertEq(outputUrl, encoded);
    }

    function testEncodeSingleCharacter() public {
        string memory data = "M";
        string[] memory encoded = new string[](1);
        encoded[0] = "TQ==";
        string[] memory outputStd = base64.encode(bytes(data), false);
        string[] memory outputUrl = base64.encode(bytes(data), true);
        assertEq(outputStd, encoded);
        assertEq(outputUrl, encoded);
    }

    function testEncodeSentence() public {
        string memory data = "Snakes are great animals!";
        string[] memory encoded = new string[](9);
        encoded[0] = "U25h";
        encoded[1] = "a2Vz";
        encoded[2] = "IGFy";
        encoded[3] = "ZSBn";
        encoded[4] = "cmVh";
        encoded[5] = "dCBh";
        encoded[6] = "bmlt";
        encoded[7] = "YWxz";
        encoded[8] = "IQ==";
        string[] memory outputStd = base64.encode(bytes(data), false);
        string[] memory outputUrl = base64.encode(bytes(data), true);
        assertEq(outputStd, encoded);
        assertEq(outputUrl, encoded);
    }

    function testEncodeSafeUrl() public {
        string memory data = "[]c!~?[]~~";
        string[] memory encodedStd = new string[](4);
        string[] memory encodedUrl = new string[](4);
        encodedStd[0] = "W11j";
        encodedStd[1] = "IX4/";
        encodedStd[2] = "W11+";
        encodedStd[3] = "fg==";
        encodedUrl[0] = "W11j";
        encodedUrl[1] = "IX4_";
        encodedUrl[2] = "W11-";
        encodedUrl[3] = "fg==";
        string[] memory outputStd = base64.encode(bytes(data), false);
        string[] memory outputUrl = base64.encode(bytes(data), true);
        assertEq(outputStd, encodedStd);
        assertEq(outputUrl, encodedUrl);
    }
}
