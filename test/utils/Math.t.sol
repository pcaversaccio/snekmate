// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.18;

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
}
