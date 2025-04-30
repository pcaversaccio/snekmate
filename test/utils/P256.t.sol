// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";

import {IP256} from "./interfaces/IP256.sol";

contract P256Test is Test {
    using BytesLib for bytes;
    using stdJson for string;

    uint256 private constant _N =
        115_792_089_210_356_248_762_697_446_949_407_573_529_996_955_224_135_760_342_422_259_061_068_512_044_369;
    uint256 private constant _MALLEABILITY_THRESHOLD =
        57_896_044_605_178_124_381_348_723_474_703_786_764_998_477_612_067_880_171_211_129_530_534_256_022_184;
    /* solhint-disable const-name-snakecase */
    bytes32 private constant hashValid = 0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023;
    uint256 private constant rValid =
        19_738_613_187_745_101_558_623_338_726_804_762_177_711_919_211_234_071_563_652_772_152_683_725_073_944;
    uint256 private constant sValid =
        34_753_961_278_895_633_991_577_816_754_222_591_531_863_837_041_401_341_770_838_584_739_693_604_822_390;
    uint256 private constant qxValid =
        18_614_955_573_315_897_657_680_976_650_685_450_080_931_919_913_269_223_958_732_452_353_593_824_192_568;
    uint256 private constant qyValid =
        90_223_116_347_859_880_166_570_198_725_387_569_567_414_254_547_569_925_327_988_539_833_150_573_990_206;
    uint256 private constant p =
        115_792_089_210_356_248_762_697_446_949_407_573_530_086_143_415_290_314_195_533_631_308_867_097_853_951;
    /* solhint-enable const-name-snakecase */

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IP256 private P256;

    function setUp() public {
        P256 = IP256(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "p256_mock"));
    }

    function testVerifyWithValidSignature() public view {
        assertTrue(P256.verify_sig(hashValid, rValid, sValid, qxValid, qyValid));
        assertTrue(!P256.verify_sig(hashValid, rValid, sValid, qxValid + 1, qyValid));
    }

    function testVerifyWithZeroInputs() public view {
        assertTrue(!P256.verify_sig(bytes32(0), 0, 0, 0, 0));
    }

    function testVerifyWithOutOfBoundsPublicKey() public view {
        assertTrue(!P256.verify_sig(hashValid, rValid, sValid, 0, 1));
        assertTrue(!P256.verify_sig(hashValid, rValid, sValid, 1, 0));
        assertTrue(!P256.verify_sig(hashValid, rValid, sValid, 1, p));
        assertTrue(!P256.verify_sig(hashValid, rValid, sValid, p, 1));
        /**
         * @dev The value `p-1` is technically in-bounds, but the point is not on the curve.
         */
        assertTrue(!P256.verify_sig(hashValid, rValid, sValid, p - 1, 1));
    }

    function testVerifyWithFlippedValues() public view {
        assertTrue(P256.verify_sig(hashValid, rValid, sValid, qxValid, qyValid));
        assertTrue(!P256.verify_sig(hashValid, sValid, rValid, qxValid, qyValid));
        assertTrue(!P256.verify_sig(hashValid, rValid, sValid, qyValid, qxValid));
        assertTrue(!P256.verify_sig(hashValid, sValid, rValid, qyValid, qxValid));
    }

    function testVerifyWithInvalidSignature() public view {
        assertTrue(!P256.verify_sig(keccak256("WAGMI"), rValid, sValid, qxValid, qyValid));
    }

    function testVerifyWycheproofData() public {
        string memory file = "test/utils/test-data/wycheproof.jsonl";
        while (true) {
            string memory vector = vm.readLine(file);
            if (bytes(vector).length == 0) {
                break;
            }

            uint256 r = uint256(vector.readBytes32(".r"));
            uint256 s = uint256(vector.readBytes32(".s"));
            uint256 x = uint256(vector.readBytes32(".x"));
            uint256 y = uint256(vector.readBytes32(".y"));
            bytes32 hash = vector.readBytes32(".hash");

            if (s <= _N) {
                assertEq(
                    P256.verify_sig(
                        hash,
                        r,
                        /**
                         * @dev Flip the `s` parameter if it is higher than the malleability threshold.
                         */
                        (s > _MALLEABILITY_THRESHOLD) ? (_N - s) : s,
                        x,
                        y
                    ),
                    vector.readBool(".valid")
                );
            } else {
                vm.expectRevert(bytes("p256: invalid signature `s` value"));
                P256.verify_sig(hash, r, s, x, y);
            }
        }
    }

    function testVerifyWithTooHighSValue() public {
        uint256 sTooHigh = sValid + _MALLEABILITY_THRESHOLD;
        vm.expectRevert(bytes("p256: invalid signature `s` value"));
        P256.verify_sig(hashValid, rValid, sTooHigh, qxValid, qyValid);
    }

    function testFuzzVerifyWithValidSignature(string calldata signer, string calldata message) public {
        (, uint256 key) = makeAddrAndKey(signer);
        key = bound(key, 1, _N - 1);
        bytes32 hash = keccak256(abi.encode(message));
        (bytes32 r, bytes32 s) = vm.signP256(key, hash);
        (uint256 qx, uint256 qy) = vm.publicKeyP256(key);
        if (uint256(s) <= _MALLEABILITY_THRESHOLD) {
            assertTrue(P256.verify_sig(hash, uint256(r), uint256(s), qx, qy));
        } else {
            vm.expectRevert(bytes("p256: invalid signature `s` value"));
            P256.verify_sig(hash, uint256(r), uint256(s), qx, qy);
        }
    }
}
