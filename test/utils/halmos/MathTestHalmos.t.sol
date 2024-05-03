// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {Math} from "openzeppelin/utils/math/Math.sol";

import {IMath} from "../interfaces/IMath.sol";

/**
 * @dev Sets the timeout (in milliseconds) for solving assertion
 * violation conditions; `0` means no timeout.
 * @custom:halmos --solver-timeout-assertion 0
 */
contract MathTestHalmos is Test, SymTest {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IMath private math;

    /**
     * @dev Sets timeout (in milliseconds) for solving branching
     * conditions; `0` means no timeout.
     * @custom:halmos --solver-timeout-branching 1000
     */
    function setUp() public {
        /**
         * @dev Halmos does not currently work with the latest Vyper jump-table-based
         * dispatchers: https://github.com/a16z/halmos/issues/253. For Halmos-based tests,
         * we therefore disable the optimiser.
         */
        math = IMath(
            vyperDeployer.deployContract(
                "src/snekmate/utils/mocks/",
                "MathMock",
                "shanghai",
                "none"
            )
        );
    }

    function testHalmosAssertMulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Math.Rounding rounding
    ) public view {
        assertEq(
            math.mul_div(x, y, denominator, Math.unsignedRoundsUp(rounding)),
            Math.mulDiv(x, y, denominator, rounding)
        );
    }

    function testHalmosAssertLog2(
        uint256 x,
        Math.Rounding rounding
    ) public view {
        assertEq(
            math.log_2(x, Math.unsignedRoundsUp(rounding)),
            Math.log2(x, rounding)
        );
    }

    function testHalmosAssertLog10(
        uint256 x,
        Math.Rounding rounding
    ) public view {
        assertEq(
            math.log_10(x, Math.unsignedRoundsUp(rounding)),
            Math.log10(x, rounding)
        );
    }

    function testHalmosAssertLog256(
        uint256 x,
        Math.Rounding rounding
    ) public view {
        assertEq(
            math.log_256(x, Math.unsignedRoundsUp(rounding)),
            Math.log256(x, rounding)
        );
    }
}
