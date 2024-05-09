// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {Math} from "openzeppelin/utils/math/Math.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {IMath} from "../interfaces/IMath.sol";

/**
 * @dev Sets the timeout (in milliseconds) for solving assertion
 * violation conditions; `0` means no timeout.
 * @notice Halmos currently does not support the new native `assert`
 * cheatcodes in `forge-std` `v1.8.0` and above.
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
                "math_mock",
                "shanghai",
                "none"
            )
        );
    }

    function testHalmosAssertUint256Average(uint256 x, uint256 y) public view {
        assert(math.uint256_average(x, y) == Math.average(x, y));
    }

    function testHalmosAssertInt256Average(int256 x, int256 y) public view {
        assert(math.int256_average(x, y) == FixedPointMathLib.avg(x, y));
    }

    function testHalmosAssertCeilDiv(uint256 x, uint256 y) public view {
        assert(math.ceil_div(x, y) == Math.ceilDiv(x, y));
    }

    function testHalmosAssertSignum(int256 x) public view {
        int256 signum;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            signum := sub(sgt(x, 0), slt(x, 0))
        }
        assert(math.signum(x) == signum);
    }

    /**
     * @dev Currently commented out, as the timeout for the Z3 solver does not work for
     * the queries of this test, where the Z3 solver is constantly running and consumes
     * a lot of memory, causing the CI to crash due to out of memory.
     */
    // function testHalmosAssertMulDiv(
    //     uint256 x,
    //     uint256 y,
    //     uint256 denominator,
    //     Math.Rounding rounding
    // ) public view {
    //     assert(
    //         math.mul_div(x, y, denominator, Math.unsignedRoundsUp(rounding)) ==
    //             Math.mulDiv(x, y, denominator, rounding)
    //     );
    // }

    function testHalmosAssertLog2(
        uint256 x,
        Math.Rounding rounding
    ) public view {
        assert(
            math.log2(x, Math.unsignedRoundsUp(rounding)) ==
                Math.log2(x, rounding)
        );
    }

    function testHalmosAssertLog10(
        uint256 x,
        Math.Rounding rounding
    ) public view {
        assert(
            math.log10(x, Math.unsignedRoundsUp(rounding)) ==
                Math.log10(x, rounding)
        );
    }

    function testHalmosAssertLog256(
        uint256 x,
        Math.Rounding rounding
    ) public view {
        assert(
            math.log256(x, Math.unsignedRoundsUp(rounding)) ==
                Math.log256(x, rounding)
        );
    }

    /**
     * @dev Currently commented out, as the timeout for the Z3 solver does not work for
     * the queries of this test, where the Z3 solver is constantly running and consumes
     * a lot of memory, causing the CI to crash due to out of memory.
     */
    // function testHalmosAssertWadLn(int256 x) public view {
    //     assert(math.wad_ln(x) == FixedPointMathLib.lnWad(x));
    // }

    /**
     * @dev Currently commented out, as the timeout for the Z3 solver does not work for
     * the queries of this test, where the Z3 solver is constantly running and consumes
     * a lot of memory, causing the CI to crash due to out of memory.
     */
    // function testHalmosAssertWadExp(int256 x) public view {
    //     assert(math.wad_exp(x) == FixedPointMathLib.expWad(x));
    // }

    /**
     * @dev Currently commented out, as the timeout for the Z3 solver does not work for
     * the queries of this test, where the Z3 solver is constantly running and consumes
     * a lot of memory, causing the CI to crash due to out of memory.
     */
    // function testHalmosAssertCbrt(uint256 x, bool roundup) public view {
    //     if (!roundup) {
    //         assert(math.cbrt(x, roundup) == FixedPointMathLib.cbrt(x));
    //     } else {
    //         assert(
    //             math.cbrt(x, roundup) >= FixedPointMathLib.cbrt(x) &&
    //                 math.cbrt(x, roundup) <= FixedPointMathLib.cbrt(x) + 1
    //         );
    //     }
    // }

    /**
     * @dev Currently commented out, as the timeout for the Z3 solver does not work for
     * the queries of this test, where the Z3 solver is constantly running and consumes
     * a lot of memory, causing the CI to crash due to out of memory.
     */
    // function testHalmosAssertWadCbrt(uint256 x) public view {
    //     assert(math.wad_cbrt(x) == FixedPointMathLib.cbrtWad(x));
    // }
}
