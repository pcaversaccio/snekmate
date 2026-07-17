// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IMath} from "./interfaces/IMath.sol";

/**
 * @title MathWadCbrtPrecisionTest
 * @notice Targeted tests that pin down the documented, branch-dependent
 *         precision behaviour of `math._wad_cbrt`.
 * @dev `_wad_cbrt` is a "wad" cube root: for an input `x = v * 1e18` it
 *      returns approximately `cbrt(v) * 1e18`. To avoid a 512-bit overflow,
 *      the internal scaling depends on the magnitude of `x`, which causes
 *      the number of accurate fractional digits of `cbrt(v)` to degrade in
 *      two steps. These tests make that behaviour explicit and regression
 *      safe: the existing `testFuzzWadCbrt` only asserts a loose
 *      `floor * 1e12 <= result <= (floor + 1) * 1e12` bound that holds
 *      regardless of the precision tier and therefore cannot detect a
 *      change in the tier cut-offs or the quantisation step. See also PR
 *      #381 which hardened the sibling `_cbrt` routine but intentionally
 *      left `_wad_cbrt` unchanged.
 *
 *      Tier cut-offs (matching the Vyper source `unsafe_div`/`unsafe_mul`):
 *        - small:  x <  max / 1e36                              -> not quantised
 *        - medium: max / 1e36 <= x < (max / 1e36) * 1e18        -> result % 1e6  == 0
 *        - large:  x >= (max / 1e36) * 1e18                      -> result % 1e12 == 0
 *
 *      Only the divisibility invariants (medium -> 1e6, large -> 1e12) are
 *      guaranteed by construction, since the medium branch returns `y * 1e6`
 *      and the large branch returns `y * 1e12`. The small tier returns the
 *      raw Newton-Raphson floor and is therefore not quantised in general;
 *      this is demonstrated via the existing `wad_cbrt(9e18)` vector rather
 *      than a generic assertion.
 */
contract MathWadCbrtPrecisionTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    IMath private math;

    uint256 private constant _MAX_OVER_1E36 = type(uint256).max / 10 ** 36;
    uint256 private constant _LARGE_TIER_THRESHOLD = (type(uint256).max / 10 ** 36) * 10 ** 18;

    /**
     * @dev Forked and adjusted accordingly from `Math.t.sol`.
     * @param n The 32-byte variable from which the cube root is calculated.
     * @return The 32-byte floor cube root of `n`.
     */
    function floorCbrt(uint256 n) internal pure returns (uint256) {
        unchecked {
            uint256 x = 0;
            for (uint256 y = 1 << type(uint8).max; y > 0; y >>= 3) {
                x <<= 1;
                uint256 z = 3 * x * (x + 1) + 1;
                if (n / y >= z) {
                    n -= y * z;
                    x += 1;
                }
            }
            return x;
        }
    }

    function setUp() public {
        math = IMath(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "math_mock"));
    }

    /**
     * @notice The large tier result is divisible by `1e12`: only ~6 fractional
     *         digits of `cbrt(v)` survive (the last 12 wad digits are zero).
     *         Reuses the exact value already asserted by `testWadCbrt` in
     *         `Math.t.sol` and additionally checks the divisibility invariant
     *         that encodes the precision loss.
     */
    function testWadCbrtLargeTierDivisibleBy1e12() public view {
        uint256 x = type(uint256).max;
        uint256 result = math.wad_cbrt(x);
        // Known vector (see `testWadCbrt`): trailing 12 digits are zero.
        assertEq(result, 48_740_834_812_604_276_470_692_694_000_000_000_000);
        assertEq(result % 10 ** 12, 0, "large tier: result must be divisible by 1e12");
        assertEq(result % 10 ** 6, 0, "large tier: result must be divisible by 1e6");
    }

    /**
     * @notice The small tier keeps the full 18-digit wad precision: the result
     *         is NOT quantised to a multiple of `1e6`. This contrasts with the
     *         medium/large tiers and makes the precision drop visible in the
     *         test suite. Uses the existing `wad_cbrt(9e18)` vector, whose low
     *         6 digits are `904_114`.
     */
    function testWadCbrtSmallTierFullPrecision() public view {
        uint256 x = 9 * 10 ** 18; // well below `max / 1e36`, i.e. small tier
        uint256 result = math.wad_cbrt(x);
        // Known vector (see `testWadCbrt`): low 6 digits are non-zero.
        assertEq(result, 2_080_083_823_051_904_114);
        assertNotEq(result % 10 ** 6, 0, "small tier: result must NOT be quantised to 1e6");
    }

    /**
     * @notice For every input in the medium tier, the result is divisible by
     *         `1e6` (last 6 wad digits are zero), i.e. only ~12 fractional
     *         digits of `cbrt(v)` survive. Guaranteed by construction since
     *         the medium branch returns `y * 1e6`.
     */
    function testFuzzWadCbrtMediumTierDivisibleBy1e6(uint256 x) public view {
        x = bound(x, _MAX_OVER_1E36, _LARGE_TIER_THRESHOLD - 1);
        uint256 result = math.wad_cbrt(x);
        assertEq(result % 10 ** 6, 0, "medium tier: result must be divisible by 1e6");
        // Bounds inherited from the (relaxed) wad invariant; allow the ±1
        // overshoot discussed in PR #381.
        uint256 floor = floorCbrt(x);
        assertTrue(result >= floor * 10 ** 12 && result <= (floor + 1) * 10 ** 12);
    }

    /**
     * @notice For every input in the large tier, the result is divisible by
     *         `1e12` (last 12 wad digits are zero), i.e. only ~6 fractional
     *         digits of `cbrt(v)` survive. Guaranteed by construction since
     *         the large branch returns `y * 1e12`.
     */
    function testFuzzWadCbrtLargeTierDivisibleBy1e12(uint256 x) public view {
        x = bound(x, _LARGE_TIER_THRESHOLD, type(uint256).max);
        uint256 result = math.wad_cbrt(x);
        assertEq(result % 10 ** 12, 0, "large tier: result must be divisible by 1e12");
        // Bounds inherited from the (relaxed) wad invariant; allow the ±1
        // overshoot discussed in PR #381.
        uint256 floor = floorCbrt(x);
        assertTrue(result >= floor * 10 ** 12 && result <= (floor + 1) * 10 ** 12);
    }

    /**
     * @notice The medium tier cut-off is exact: at `x = max / 1e36` the result
     *         is divisible by `1e6` (medium tier kicks in). The non-quantised
     *         behaviour of the small tier is demonstrated in
     *         `testWadCbrtSmallTierFullPrecision` via a known vector, since a
     *         generic small-tier input is not guaranteed to be non-divisible
     *         by `1e6`.
     */
    function testWadCbrtMediumTierBoundary() public view {
        uint256 atThreshold = _MAX_OVER_1E36;
        assertEq(
            math.wad_cbrt(atThreshold) % 10 ** 6,
            0,
            "medium tier boundary: result must be divisible by 1e6"
        );
    }

    /**
     * @notice The large tier cut-off is exact: just below it the result is
     *         divisible by `1e6` (medium tier) but not necessarily by `1e12`,
     *         while at and above it the result must be divisible by `1e12`.
     *         Both divisibility properties are guaranteed by construction.
     */
    function testWadCbrtLargeTierBoundary() public view {
        uint256 justBelow = _LARGE_TIER_THRESHOLD - 1;
        uint256 atThreshold = _LARGE_TIER_THRESHOLD;
        assertEq(
            math.wad_cbrt(justBelow) % 10 ** 6,
            0,
            "medium tier (just below large): result must be divisible by 1e6"
        );
        assertEq(
            math.wad_cbrt(atThreshold) % 10 ** 12,
            0,
            "large tier boundary: result must be divisible by 1e12"
        );
    }
}
