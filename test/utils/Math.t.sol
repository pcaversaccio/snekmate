// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IMath} from "./interfaces/IMath.sol";

contract MathTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IMath private math;

    /**
     * @dev An `internal` helper function that uses inline assembly to
     * perform a `mulmod` operation.
     * @param x The 32-byte multiplicand.
     * @param y The 32-byte multiplier.
     * @param denominator The 32-byte divisor.
     * @return result The 32-byte result of the `mulmod` operation.
     */
    function mulMod(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mulmod(x, y, denominator)
        }
    }

    /**
     * @dev An `internal` helper function to calculate the full precision
     * for "x * y".
     * @param x The 32-byte multiplicand.
     * @param y The 32-byte multiplier.
     * @return high The most significant 32 bytes of the product.
     * @return low The least significant 32 bytes of the product.
     */
    function mulHighLow(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 high, uint256 low) {
        (uint256 x0, uint256 x1) = (x & type(uint128).max, x >> 128);
        (uint256 y0, uint256 y1) = (y & type(uint128).max, y >> 128);

        /**
         * @dev Karatsuba algorithm: https://en.wikipedia.org/wiki/Karatsuba_algorithm.
         */
        uint256 z2 = x1 * y1;
        uint256 z1a = x1 * y0;
        uint256 z1b = x0 * y1;
        uint256 z0 = x0 * y0;

        uint256 carry = ((z1a & type(uint128).max) +
            (z1b & type(uint128).max) +
            (z0 >> 128)) >> 128;

        high = z2 + (z1a >> 128) + (z1b >> 128) + carry;

        unchecked {
            low = x * y;
        }
    }

    /**
     * @dev An `internal` helper function for internal remainder calculation
     * and carry addition.
     * @param x The least significant 32 bytes.
     * @param y The 32-byte result of a `mulmod` operation.
     * @return remainder The 32-byte remainder.
     * @return carry The 32-byte carry.
     */
    function addCarry(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 remainder, uint256 carry) {
        unchecked {
            remainder = x + y;
        }
        carry = remainder < x ? 1 : 0;
    }

    function setUp() public {
        math = IMath(vyperDeployer.deployContract("src/utils/", "Math"));
    }

    function testMulDivDivisionByZero() public {
        vm.expectRevert(bytes("Math: mul_div division by zero"));
        math.mul_div(1, 1, 0, false);
        vm.expectRevert(bytes("Math: mul_div division by zero"));
        math.mul_div(1, 1, 0, true);
    }

    function testMulDivOverflow() public {
        vm.expectRevert(bytes("Math: mul_div overflow"));
        math.mul_div(type(uint256).max, type(uint256).max, 1, false);
        vm.expectRevert(bytes("Math: mul_div overflow"));
        math.mul_div(type(uint256).max, type(uint256).max, 1, true);
    }

    function testMulDivRoundDownSmallValues() public {
        assertEq(math.mul_div(3, 4, 5, false), 2);
        assertEq(math.mul_div(5, 7, 6, false), 5);
        assertEq(math.mul_div(7, 9, 8, false), 7);
    }

    function testMulDivRoundDownLargeValues() public {
        uint256 maxUint256 = type(uint256).max;
        uint256 maxUint256Sub1 = maxUint256 - 1;
        uint256 maxUint256Sub2 = maxUint256 - 2;
        assertEq(math.mul_div(42, maxUint256Sub1, maxUint256, false), 41);
        assertEq(math.mul_div(23, maxUint256, maxUint256, false), 23);
        assertEq(
            math.mul_div(maxUint256Sub1, maxUint256Sub1, maxUint256, false),
            maxUint256Sub2
        );
        assertEq(
            math.mul_div(maxUint256, maxUint256Sub1, maxUint256, false),
            maxUint256Sub1
        );
        assertEq(
            math.mul_div(maxUint256, maxUint256, maxUint256, false),
            maxUint256
        );
    }

    function testMulDivRoundUpSmallValues() public {
        assertEq(math.mul_div(3, 4, 5, true), 3);
        assertEq(math.mul_div(5, 7, 6, true), 6);
        assertEq(math.mul_div(7, 9, 8, true), 8);
    }

    function testMulDivRoundUpLargeValues() public {
        uint256 maxUint256 = type(uint256).max;
        uint256 maxUint256Sub1 = maxUint256 - 1;
        assertEq(math.mul_div(42, maxUint256Sub1, maxUint256, true), 42);
        assertEq(math.mul_div(23, maxUint256, maxUint256, true), 23);
        assertEq(
            math.mul_div(maxUint256Sub1, maxUint256Sub1, maxUint256, true),
            maxUint256Sub1
        );
        assertEq(
            math.mul_div(maxUint256, maxUint256Sub1, maxUint256, true),
            maxUint256Sub1
        );
        assertEq(
            math.mul_div(maxUint256, maxUint256, maxUint256, true),
            maxUint256
        );
    }

    function testUint256Average() public {
        assertEq(math.uint256_average(83219, 219713), 151466);
        assertEq(math.uint256_average(73220, 419712), 246466);
        assertEq(math.uint256_average(83219, 419712), 251465);
        assertEq(math.uint256_average(73220, 219713), 146466);
        assertEq(
            math.uint256_average(type(uint256).max, type(uint256).max),
            type(uint256).max
        );
    }

    function testInt256Average() public {
        assertEq(math.int256_average(83219, 219713), 151466);
        assertEq(math.int256_average(-83219, -219713), -151466);

        assertEq(math.int256_average(-73220, 419712), 173246);
        assertEq(math.int256_average(73220, -419712), -173246);

        assertEq(math.int256_average(83219, -419712), -168247);
        assertEq(math.int256_average(-83219, 419712), 168246);

        assertEq(math.int256_average(73220, 219713), 146466);
        assertEq(math.int256_average(-73220, -219713), -146467);

        assertEq(
            math.int256_average(type(int256).min, type(int256).min),
            type(int256).min
        );
        assertEq(math.int256_average(type(int256).min, type(int256).max), -1);
    }

    function testCeilDiv() public {
        assertEq(math.ceil_div(0, 8), 0);
        assertEq(math.ceil_div(12, 6), 2);
        assertEq(math.ceil_div(123, 17), 8);
        assertEq(math.ceil_div(type(uint256).max, 2), 1 << 255);
        assertEq(math.ceil_div(type(uint256).max, 1), type(uint256).max);
        vm.expectRevert(bytes("Math: ceil_div division by zero"));
        math.ceil_div(1, 0);
    }

    function testLog2RoundDown() public {
        assertEq(math.log_2(0, false), 0);
        assertEq(math.log_2(1, false), 0);
        assertEq(math.log_2(2, false), 1);
        assertEq(math.log_2(3, false), 1);
        assertEq(math.log_2(4, false), 2);
        assertEq(math.log_2(5, false), 2);
        assertEq(math.log_2(6, false), 2);
        assertEq(math.log_2(7, false), 2);
        assertEq(math.log_2(8, false), 3);
        assertEq(math.log_2(9, false), 3);
        assertEq(math.log_2(type(uint256).max, false), 255);
    }

    function testLog2RoundUp() public {
        assertEq(math.log_2(0, true), 0);
        assertEq(math.log_2(1, true), 0);
        assertEq(math.log_2(2, true), 1);
        assertEq(math.log_2(3, true), 2);
        assertEq(math.log_2(4, true), 2);
        assertEq(math.log_2(5, true), 3);
        assertEq(math.log_2(6, true), 3);
        assertEq(math.log_2(7, true), 3);
        assertEq(math.log_2(8, true), 3);
        assertEq(math.log_2(9, true), 4);
        assertEq(math.log_2(type(uint256).max, true), 256);
    }

    function testLog10RoundDown() public {
        assertEq(math.log_10(0, false), 0);
        assertEq(math.log_10(1, false), 0);
        assertEq(math.log_10(2, false), 0);
        assertEq(math.log_10(9, false), 0);
        assertEq(math.log_10(10, false), 1);
        assertEq(math.log_10(11, false), 1);
        assertEq(math.log_10(99, false), 1);
        assertEq(math.log_10(100, false), 2);
        assertEq(math.log_10(101, false), 2);
        assertEq(math.log_10(999, false), 2);
        assertEq(math.log_10(1000, false), 3);
        assertEq(math.log_10(1001, false), 3);
        assertEq(math.log_10(type(uint256).max, false), 77);
    }

    function testLog10RoundUp() public {
        assertEq(math.log_10(0, true), 0);
        assertEq(math.log_10(1, true), 0);
        assertEq(math.log_10(2, true), 1);
        assertEq(math.log_10(9, true), 1);
        assertEq(math.log_10(10, true), 1);
        assertEq(math.log_10(11, true), 2);
        assertEq(math.log_10(99, true), 2);
        assertEq(math.log_10(100, true), 2);
        assertEq(math.log_10(101, true), 3);
        assertEq(math.log_10(999, true), 3);
        assertEq(math.log_10(1000, true), 3);
        assertEq(math.log_10(1001, true), 4);
        assertEq(math.log_10(type(uint256).max, true), 78);
    }

    function testLog256RoundDown() public {
        assertEq(math.log_256(0, false), 0);
        assertEq(math.log_256(1, false), 0);
        assertEq(math.log_256(2, false), 0);
        assertEq(math.log_256(255, false), 0);
        assertEq(math.log_256(256, false), 1);
        assertEq(math.log_256(257, false), 1);
        assertEq(math.log_256(65535, false), 1);
        assertEq(math.log_256(65536, false), 2);
        assertEq(math.log_256(65537, false), 2);
        assertEq(math.log_256(type(uint256).max, false), 31);
    }

    function testLog256RoundUp() public {
        assertEq(math.log_256(0, true), 0);
        assertEq(math.log_256(1, true), 0);
        assertEq(math.log_256(2, true), 1);
        assertEq(math.log_256(255, true), 1);
        assertEq(math.log_256(256, true), 1);
        assertEq(math.log_256(257, true), 2);
        assertEq(math.log_256(65535, true), 2);
        assertEq(math.log_256(65536, true), 2);
        assertEq(math.log_256(65537, true), 3);
        assertEq(math.log_256(type(uint256).max, true), 32);
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/math/Math.t.sol.
     */
    function testFuzzMulDiv(uint256 x, uint256 y, uint256 d) public {
        /**
         * @dev Full precision for "x * y".
         */
        (uint256 xyHi, uint256 xyLo) = mulHighLow(x, y);

        /**
         * @dev Assume the result will not overflow (see `testFuzzMulDivDomain`).
         * This also checks that `d` is positive.
         */
        vm.assume(xyHi < d);

        uint256 qDown = math.mul_div(x, y, d, false);

        /**
         * @dev Full precision for "q * d".
         */
        (uint256 qdHi, uint256 qdLo) = mulHighLow(qDown, d);
        /**
         * @dev Add remainder of "(x * y) / d", computed as "remainder = ((x * y) % d)".
         */
        (uint256 qdRemLo, uint256 c) = addCarry(qdLo, mulMod(x, y, d));
        uint256 qdRemHi = qdHi + c;

        /**
         * @dev Full precision check that "x * y = q * d + remainder" holds.
         */
        assertEq(xyHi, qdRemHi);
        assertEq(xyLo, qdRemLo);

        /**
         * @dev Full precision check in case of "ceil((x * y) / denominator)".
         */
        vm.assume(mulmod(x, y, d) > 0 && qDown < type(uint256).max);
        assertEq(math.mul_div(x, y, d, true), qDown + 1);
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/math/Math.t.sol.
     */
    function testFuzzMulDivDomain(uint256 x, uint256 y, uint256 d) public {
        (uint256 xyHi, ) = mulHighLow(x, y);

        /**
         * @dev Violate `testFuzzMulDiv` assumption, i.e. `d` is 0 and result overflows.
         */
        vm.assume(xyHi >= d);

        try math.mul_div(x, y, d, false) returns (uint256) {
            fail();
        } catch {}
        try math.mul_div(x, y, d, true) returns (uint256) {
            fail();
        } catch {}
    }

    /**
     * @notice We use the `average` function of OpenZeppelin as a benchmark:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
     */
    function testFuzzUint256Average(uint256 x, uint256 y) public {
        assertEq(math.uint256_average(x, y), (x & y) + ((x ^ y) / 2));
    }

    /**
     * @notice We use the `avg` function of solady as a benchmark:
     * https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol.
     */
    function testFuzzInt256Average(int256 x, int256 y) public {
        assertEq(
            math.int256_average(x, y),
            (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1)
        );
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/math/Math.t.sol.
     */
    function testFuzzCeilDiv(uint256 x, uint256 y) public {
        vm.assume(y > 0);
        uint256 result = math.ceil_div(x, y);
        if (result == 0) {
            assertEq(x, 0);
        } else {
            uint256 maxDiv = type(uint256).max / y;
            bool overflow = maxDiv * y < x;
            assertTrue(x > y * (result - 1));
            assertTrue(overflow ? result == maxDiv + 1 : x <= y * result);
        }
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/math/Math.t.sol.
     */
    function testFuzzLog2(uint256 x, bool roundup) public {
        uint256 result = math.log_2(x, roundup);
        if (x == 0) {
            assertEq(result, 0);
        } else if (result >= 256 || 2 ** result > x) {
            assertTrue(roundup);
            assertTrue(2 ** (result - 1) < x);
        } else if (2 ** result < x) {
            assertTrue(!roundup);
            assertTrue((result + 1) >= 256 || 2 ** (result + 1) > x);
        } else {
            assertEq(2 ** result, x);
        }
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/math/Math.t.sol.
     */
    function testFuzzLog10(uint256 x, bool roundup) public {
        uint256 result = math.log_10(x, roundup);
        if (x == 0) {
            assertEq(result, 0);
        } else if (result >= 78 || 10 ** result > x) {
            assertTrue(roundup);
            assertTrue(10 ** (result - 1) < x);
        } else if (10 ** result < x) {
            assertTrue(!roundup);
            assertTrue((result + 1) >= 78 || 10 ** (result + 1) > x);
        } else {
            assertEq(10 ** result, x);
        }
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/math/Math.t.sol.
     */
    function testFuzzLog256(uint256 x, bool roundup) public {
        uint256 result = math.log_256(x, roundup);
        if (x == 0) {
            assertEq(result, 0);
        } else if (result >= 32 || 256 ** result > x) {
            assertTrue(roundup);
            assertTrue(256 ** (result - 1) < x);
        } else if (256 ** result < x) {
            assertTrue(!roundup);
            assertTrue((result + 1) >= 32 || 256 ** (result + 1) > x);
        } else {
            assertEq(256 ** result, x);
        }
    }
}
