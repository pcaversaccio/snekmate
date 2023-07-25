// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {PRBTest} from "prb/test/PRBTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";

import {IBase64} from "./interfaces/IBase64.sol";

/**
 * @dev We make use of Paul's testing assertions (https://github.com/paulrberg/prb-test)
 * in this test suite since it supports natively equality assertions for arrays.
 */
contract Base64Test is PRBTest {
    using BytesLib for bytes;

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

    function testDecodeEmptyString() public {
        bytes[] memory outputStd = base64.decode("", false);
        bytes[] memory outputUrl = base64.decode("", true);
        assertEq(outputStd.length, 0);
        assertEq(outputUrl.length, 0);
    }

    function testDecodeWithNoPadding() public {
        string memory text = "test12";
        string memory data = "dGVzdDEy";
        bytes[] memory outputStd = base64.decode(data, false);
        bytes[] memory outputUrl = base64.decode(data, true);
        assertEq(string(bytes.concat(outputStd[0], outputStd[1])), text);
        assertEq(string(bytes.concat(outputUrl[0], outputUrl[1])), text);
    }

    function testDecodeWithSinglePadding() public {
        string memory text = "test1";
        string memory data = "dGVzdDE=";
        bytes[] memory outputStd = base64.decode(data, false);
        bytes[] memory outputUrl = base64.decode(data, true);
        bytes memory returnDataStd = bytes.concat(outputStd[0], outputStd[1]);
        bytes memory returnDataUrl = bytes.concat(outputUrl[0], outputUrl[1]);
        /**
         * @dev We remove the one trailing zero byte that stems from
         * the padding to ensure byte-level equality.
         */
        assertEq(
            string(returnDataStd.slice(0, returnDataStd.length - 1)),
            text
        );
        assertEq(
            string(returnDataUrl.slice(0, returnDataUrl.length - 1)),
            text
        );
    }

    function testDecodeWithDoublePadding() public {
        string memory text = "test";
        string memory data = "dGVzdA==";
        bytes[] memory outputStd = base64.decode(data, false);
        bytes[] memory outputUrl = base64.decode(data, true);
        bytes memory returnDataStd = bytes.concat(outputStd[0], outputStd[1]);
        bytes memory returnDataUrl = bytes.concat(outputUrl[0], outputUrl[1]);
        /**
         * @dev We remove the two trailing zero bytes that stem from
         * the padding to ensure byte-level equality.
         */
        assertEq(
            string(returnDataStd.slice(0, returnDataStd.length - 2)),
            text
        );
        assertEq(
            string(returnDataUrl.slice(0, returnDataUrl.length - 2)),
            text
        );
    }

    function testDecodeSingleCharacter() public {
        string memory text = "M";
        string memory data = "TQ==";
        bytes[] memory outputStd = base64.decode(data, false);
        bytes[] memory outputUrl = base64.decode(data, true);
        /**
         * @dev We remove the two trailing zero bytes that stem from
         * the padding to ensure byte-level equality.
         */
        assertEq(string(outputStd[0].slice(0, outputStd[0].length - 2)), text);
        assertEq(string(outputUrl[0].slice(0, outputUrl[0].length - 2)), text);
    }

    function testDecodeSentence() public {
        string memory text = "Snakes are great animals!";
        string memory data = "U25ha2VzIGFyZSBncmVhdCBhbmltYWxzIQ==";
        bytes[] memory outputStd = base64.decode(data, false);
        bytes[] memory outputUrl = base64.decode(data, true);
        bytes memory returnDataStd = bytes.concat(
            outputStd[0],
            outputStd[1],
            outputStd[2],
            outputStd[3],
            outputStd[4],
            outputStd[5],
            outputStd[6],
            outputStd[7],
            outputStd[8]
        );
        bytes memory returnDataUrl = bytes.concat(
            outputUrl[0],
            outputUrl[1],
            outputUrl[2],
            outputUrl[3],
            outputUrl[4],
            outputUrl[5],
            outputUrl[6],
            outputUrl[7],
            outputUrl[8]
        );
        /**
         * @dev We remove the two trailing zero bytes that stem from
         * the padding to ensure byte-level equality.
         */
        assertEq(
            string(returnDataStd.slice(0, returnDataStd.length - 2)),
            text
        );
        assertEq(
            string(returnDataUrl.slice(0, returnDataUrl.length - 2)),
            text
        );
    }

    function testDecodeSafeUrl() public {
        string memory text = "[]c!~?[]~";
        string memory data = "W11jIX4_W11-";
        vm.expectRevert(bytes("Base64: invalid string"));
        base64.decode(data, false);
        bytes[] memory outputUrl = base64.decode(data, true);
        bytes memory returnDataUrl = bytes.concat(
            outputUrl[0],
            outputUrl[1],
            outputUrl[2]
        );
        assertEq(string(returnDataUrl), text);
    }

    function testDataLengthMismatch() public {
        string memory data = "W11jI";
        vm.expectRevert(bytes("Base64: length mismatch"));
        base64.decode(data, false);
        vm.expectRevert(bytes("Base64: length mismatch"));
        base64.decode(data, true);
    }
}
