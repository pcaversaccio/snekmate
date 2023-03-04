# @version ^0.3.7
"""
@title Standard Mathematical Utility Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@custom:coauthor bout3fiddy
@notice These functions implement standard mathematical utility
        functions that are missing in the Vyper language. If a
        function is inspired by an existing implementation, it
        is properly referenced in the function docstring.
"""


@external
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@external
@pure
def mul_div(x: uint256, y: uint256, denominator: uint256, roundup: bool) -> uint256:
    """
    @dev Calculates "(x * y) / denominator" in 512-bit precision,
         following the selected rounding direction.
    @notice The implementation is inspired by Remco Bloemen's
            implementation under the MIT license here:
            https://xn--2-umb.com/21/muldiv.
            Furthermore, the rounding direction design pattern is
            inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte multiplicand.
    @param y The 32-byte multiplier.
    @param denominator The 32-byte divisor.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    # Handle division by zero.
    assert denominator != empty(uint256), "Math: mul_div division by zero"

    # 512-bit multiplication "[prod1 prod0] = x * y".
    # Compute the product "mod 2**256" and "mod 2**256 - 1".
    # Then use the Chinese Remainder theorem to reconstruct
    # the 512-bit result. The result is stored in two 256-bit
    # variables, where: "product = prod1 * 2**256 + prod0".
    mm: uint256 = uint256_mulmod(x, y, max_value(uint256))
    # The least significant 256 bits of the product.
    prod0: uint256 = unsafe_mul(x, y)
    # The most significant 256 bits of the product.
    prod1: uint256 = empty(uint256)

    if (mm < prod0):
        prod1 = unsafe_sub(unsafe_sub(mm, prod0), 1)
    else:
        prod1 = unsafe_sub(mm, prod0)

    # Handling of non-overflow cases, 256 by 256 division.
    if (prod1 == empty(uint256)):
        if (roundup and uint256_mulmod(x, y, denominator) != empty(uint256)):
            # Calculate "ceil((x * y) / denominator)". The following
            # line cannot overflow because we have the previous check
            # "(x * y) % denominator != 0", which accordingly rules out
            # the possibility of "x * y = 2**256 - 1" and `denominator == 1`.
            return unsafe_add(unsafe_div(prod0, denominator), 1)
        else:
            return unsafe_div(prod0, denominator)

    # Ensure that the result is less than 2**256. Also,
    # prevents that `denominator == 0`.
    assert denominator > prod1, "Math: mul_div overflow"

    #######################
    # 512 by 256 Division #
    #######################

    # Make division exact by subtracting the remainder
    # from "[prod1 prod0]". First, compute remainder using
    # the `uint256_mulmod` operation.
    remainder: uint256 = uint256_mulmod(x, y, denominator)

    # Second, subtract the 256-bit number from the 512-bit
    # number.
    if (remainder > prod0):
        prod1 = unsafe_sub(prod1, 1)
    prod0 = unsafe_sub(prod0, remainder)

    # Factor powers of two out of the denominator and calculate
    # the largest power of two divisor of denominator. Always `>= 1`,
    # unless the denominator is zero (which is prevented above),
    # in which case `twos` is zero. For more details, please refer to:
    # https://cs.stackexchange.com/q/138556.

    # The following line does not overflow because the denominator
    # cannot be zero at this stage of the function.
    twos: uint256 = denominator & (unsafe_add(~denominator, 1))
    # Divide denominator by `twos`.
    denominator_div: uint256 = unsafe_div(denominator, twos)
    # Divide "[prod1 prod0]" by `twos`.
    prod0 = unsafe_div(prod0, twos)
    # Flip `twos` such that it is "2**256 / twos". If `twos` is zero,
    # it becomes one.
    twos = unsafe_add(unsafe_div(unsafe_sub(empty(uint256), twos), twos), 1)

    # Shift bits from `prod1` to `prod0`.
    prod0 |= unsafe_mul(prod1, twos)

    # Invert the denominator "mod 2**256". Since the denominator is
    # now an odd number, it has an inverse modulo 2**256, so we have:
    # "denominator * inverse = 1 mod 2**256". Calculate the inverse by
    # starting with a seed that is correct for four bits. That is,
    # "denominator * inverse = 1 mod 2**4".
    inverse: uint256 = unsafe_mul(3, denominator_div) ^ 2

    # Use Newton-Raphson iteration to improve accuracy. Thanks to Hensel's
    # lifting lemma, this also works in modular arithmetic by doubling the
    # correct bits in each step.
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**8".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**16".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**32".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**64".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**128".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**256".

    # Since the division is now exact, we can divide by multiplying
    # with the modular inverse of the denominator. This returns the
    # correct result modulo 2**256. Since the preconditions guarantee
    # that the result is less than 2**256, this is the final result.
    # We do not need to calculate the high bits of the result and
    # `prod1` is no longer necessary.
    result: uint256 = unsafe_mul(prod0, inverse)

    if (roundup and uint256_mulmod(x, y, denominator) != empty(uint256)):
        # Calculate "ceil((x * y) / denominator)". The following
        # line uses intentionally checked arithmetic to prevent
        # a theoretically possible overflow.
        result += 1

    return result


@external
@pure
def uint256_average(x: uint256, y: uint256) -> uint256:
    """
    @dev Returns the average of two 32-byte unsigned integers.
    @notice Note that the result is rounded towards zero. For
            more details on finding the average of two unsigned
            integers without an overflow, please refer to:
            https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223.
    @param x The first 32-byte unsigned integer of the data set.
    @param y The second 32-byte unsigned integer of the data set.
    @return uint256 The 32-byte average (rounded towards zero) of
            `x` and `y`.
    """
    return unsafe_add(x & y, shift(x ^ y, -1))


@external
@pure
def int256_average(x: int256, y: int256) -> int256:
    """
    @dev Returns the average of two 32-byte signed integers.
    @notice Note that the result is rounded towards infinity.
            For more details on finding the average of two signed
            integers without an overflow, please refer to:
            https://patents.google.com/patent/US6007232A/en.
    @param x The first 32-byte signed integer of the data set.
    @param y The second 32-byte signed integer of the data set.
    @return uint256 The 32-byte average (rounded towards infinity)
            of `x` and `y`.
    """
    return unsafe_add(unsafe_add(shift(x, -1), shift(y, -1)), x & y & 1)


@external
@pure
def ceil_div(x: uint256, y: uint256) -> uint256:
    """
    @dev Calculates "ceil(x / y)" for any strictly positive `y`.
    @notice The implementation is inspired by OpenZeppelin's
            implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte numerator.
    @param y The 32-byte denominator.
    @return uint256 The 32-byte rounded up result of "x/y".
    """
    assert y != empty(uint256), "Math: ceil_div division by zero"
    if (x == empty(uint256)):
        return empty(uint256)
    else:
        return unsafe_add(unsafe_div(x - 1, y), 1)


@external
@pure
def log_2(x: uint256, roundup: bool) -> uint256:
    """
    @dev Returns the log in base 2 of `x`, following the selected
         rounding direction.
    @notice Note that it returns 0 if given 0. The implementation is
            inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte variable.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    value: uint256 = x
    result: uint256 = empty(uint256)

    if (x == empty(uint256)):
        # For the special case `x == 0` we already return 0 here in order
        # not to iterate through the remaining code.
        return empty(uint256)

    # The following lines cannot overflow because we have the well-known
    # decay behaviour of `log_2(max_value(uint256)) < max_value(uint256)`.
    if (shift(x, -128) != empty(uint256)):
        value = shift(x, -128)
        result = 128
    if (shift(value, -64) != empty(uint256)):
        value = shift(value, -64)
        result = unsafe_add(result, 64)
    if (shift(value, -32) != empty(uint256)):
        value = shift(value, -32)
        result = unsafe_add(result, 32)
    if (shift(value, -16) != empty(uint256)):
        value = shift(value, -16)
        result = unsafe_add(result, 16)
    if (shift(value, -8) != empty(uint256)):
        value = shift(value, -8)
        result = unsafe_add(result, 8)
    if (shift(value, -4) != empty(uint256)):
        value = shift(value, -4)
        result = unsafe_add(result, 4)
    if (shift(value, -2) != empty(uint256)):
        value = shift(value, -2)
        result = unsafe_add(result, 2)
    if (shift(value, -1) != empty(uint256)):
        result = unsafe_add(result, 1)

    if (roundup and (shift(1, convert(result, int256)) < x)):
        result = unsafe_add(result, 1)

    return result


@external
@pure
def log_10(x: uint256, roundup: bool) -> uint256:
    """
    @dev Returns the log in base 10 of `x`, following the selected
         rounding direction.
    @notice Note that it returns 0 if given 0. The implementation is
            inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte variable.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    value: uint256 = x
    result: uint256 = empty(uint256)

    if (x == empty(uint256)):
        # For the special case `x == 0` we already return 0 here in order
        # not to iterate through the remaining code.
        return empty(uint256)

    # The following lines cannot overflow because we have the well-known
    # decay behaviour of `log_10(max_value(uint256)) < max_value(uint256)`.
    if (x >= 10 ** 64):
        value = unsafe_div(x, 10 ** 64)
        result = 64
    if (value >= 10 ** 32):
        value = unsafe_div(value, 10 ** 32)
        result = unsafe_add(result, 32)
    if (value >= 10 ** 16):
        value = unsafe_div(value, 10 ** 16)
        result = unsafe_add(result, 16)
    if (value >= 10 ** 8):
        value = unsafe_div(value, 10 ** 8)
        result = unsafe_add(result, 8)
    if (value >= 10 ** 4):
        value = unsafe_div(value, 10 ** 4)
        result = unsafe_add(result, 4)
    if (value >= 10 ** 2):
        value = unsafe_div(value, 10 ** 2)
        result = unsafe_add(result, 2)
    if (value >= 10):
        result = unsafe_add(result, 1)

    if (roundup and (10 ** result < x)):
        result = unsafe_add(result, 1)

    return result


@external
@pure
def log_256(x: uint256, roundup: bool) -> uint256:
    """
    @dev Returns the log in base 256 of `x`, following the selected
         rounding direction.
    @notice Note that it returns 0 if given 0. Also, adding one to the
            rounded down result gives the number of pairs of hex symbols
            needed to represent `x` as a hex string. The implementation is
            inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte variable.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    value: uint256 = x
    result: uint256 = empty(uint256)

    if (x == empty(uint256)):
        # For the special case `x == 0` we already return 0 here in order
        # not to iterate through the remaining code.
        return empty(uint256)

    # The following lines cannot overflow because we have the well-known
    # decay behaviour of `log_256(max_value(uint256)) < max_value(uint256)`.
    if (shift(x, -128) != empty(uint256)):
        value = shift(x, -128)
        result = 16
    if (shift(value, -64) != empty(uint256)):
        value = shift(value, -64)
        result = unsafe_add(result, 8)
    if (shift(value, -32) != empty(uint256)):
        value = shift(value, -32)
        result = unsafe_add(result, 4)
    if (shift(value, -16) != empty(uint256)):
        value = shift(value, -16)
        result = unsafe_add(result, 2)
    if (shift(value, -8) != empty(uint256)):
        result = unsafe_add(result, 1)

    if (roundup and (shift(1, convert(shift(result, 3), int256)) < x)):
        result = unsafe_add(result, 1)

    return result


@external
@view
def cbrt(x: uint256, roundup: bool) -> uint256:
    """
    @dev Calculates the cube root of an unsigned integer.
    @notice Note that this function consumes about 1,950 to 2,050 gas units
            depending on the value of `x` and `roundup`. The implementation is
            inspired by Curve Finance's implementation under the MIT license here:
            https://github.com/curvefi/tricrypto-ng/blob/main/contracts/CurveCryptoMathOptimized3.vy.
    @param x The 32-byte variable from which the cube root is calculated.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return The 32-byte cube root of `x`.
    """
    if (x == empty(uint256)):
        # For the special case `x == 0` we already return 0 here in order
        # not to iterate through the remaining code.
        return empty(uint256)

    y: uint256 = unsafe_div(self._wad_cbrt(x), 10 ** 12)

    if (roundup and (unsafe_mul(unsafe_mul(y, y), y) != x)):
        y = unsafe_add(y, 1)

    return y


@external
@pure
def wad_cbrt(x: uint256) -> uint256:
    """
    @dev Calculates the cube root of an unsigned integer with a precision
         of 1e18.
    @notice Note that this function consumes about 1,850 to 1,950 gas units
            depending on the value of `x`. The implementation is inspired
            by Curve Finance's implementation under the MIT license here:
            https://github.com/curvefi/tricrypto-ng/blob/main/contracts/CurveCryptoMathOptimized3.vy.
    @param x The 32-byte variable from which the cube root is calculated.
    @return The 32-byte cubic root of `x` with a precision of 1e18.
    """
    if (x == empty(uint256)):
        # For the special case `x == 0` we already return 0 here in order
        # not to iterate through the remaining code.
        return empty(uint256)

    return self._wad_cbrt(x)


@external
@pure
def is_negative(x: int256) -> bool:
    """
    @dev Returns `True` if a 32-byte signed integer is negative.
    @notice Note that this function returns `False` for 0.
    @param x The 32-byte signed integer variable.
    @return bool The verification whether `x` is negative or not.
    """
    return (x ^ 1 < empty(int256))


@internal
@pure
def _wad_cbrt(x: uint256) -> uint256:
    """
    @dev An `internal` helper function that calculates the cube root of an
         unsigned integer with a precision of 1e18.
    @notice Note that this function consumes about 1,800 to 1,850 gas units
            depending on the value of `x`. The implementation is inspired
            by Curve Finance's implementation under the MIT license here:
            https://github.com/curvefi/tricrypto-ng/blob/main/contracts/CurveCryptoMathOptimized3.vy.
    @param x The 32-byte variable from which the cube root is calculated.
    @return The 32-byte cubic root of `x` with a precision of 1e18.
    """
    # Since this cube root is for numbers with base 1e18, we have to scale
    # the input by 1e36 to increase the precision. This leads to an overflow
    # for very large numbers. So we conditionally sacrifice precision.
    xx: uint256 = empty(uint256)
    if (x >= unsafe_mul(unsafe_div(max_value(uint256), 10 ** 36), 10 ** 18)):
        xx = x
    elif (x >= unsafe_div(max_value(uint256), 10 ** 36)):
        xx = unsafe_mul(x, 10 ** 18)
    else:
        xx = unsafe_mul(x, 10 ** 36)

    # Compute the binary logarithm of `xx`. This approach was inspired by Sean
    # Eron Anderson's "Bit Twiddling Hacks" from Stanford:
    # https://graphics.stanford.edu/~seander/bithacks.html#IntegerLog.
    # Further inspiration stems from solmate:
    # https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol.
    # A detailed mathematical explanation by Remco Bloemen can be found here:
    # https://xn--2-umb.com/22/exp-ln.
    log2x: uint256 = empty(uint256)
    if (xx > max_value(uint128)):
        log2x = 128
    if (unsafe_div(xx, shift(2, convert(log2x, int256))) > max_value(uint64)):
        log2x = log2x | 64
    if (unsafe_div(xx, shift(2, convert(log2x, int256))) > max_value(uint32)):
        log2x = log2x | 32
    if (unsafe_div(xx, shift(2, convert(log2x, int256))) > max_value(uint16)):
        log2x = log2x | 16
    if (unsafe_div(xx, shift(2, convert(log2x, int256))) > max_value(uint8)):
        log2x = log2x | 8
    if (unsafe_div(xx, shift(2, convert(log2x, int256))) > 15):
        log2x = log2x | 4
    if (unsafe_div(xx, shift(2, convert(log2x, int256))) > 3):
        log2x = log2x | 2
    if (unsafe_div(xx, shift(2, convert(log2x, int256))) > 1):
        log2x = log2x | 1

    # If we divide log2x by 3, the remainder is "log2x % 3". So if we simply
    # multiply "2 ** (log2x/3)" and discard the remainder to calculate our guess,
    # the Newton-Raphson method takes more iterations to converge to a solution
    # because it lacks this precision. A few more calculations now in order to
    # do fewer calculations later:
    #   - "pow = log2(x) // 3" (the operator `//` means integer division),
    #   - "remainder = log2(x) % 3",
    #   - "initial_guess = 2 ** pow * cbrt(2) ** remainder".
    # Now substituting "2 = 1.26 ≈ 1260 / 1000", we get:
    #   - "initial_guess = 2 ** pow * 1260 ** remainder // 1000 ** remainder".
    remainder: uint256 = log2x % 3
    y: uint256 = unsafe_div(unsafe_mul(pow_mod256(2, unsafe_div(log2x, 3)), pow_mod256(1260, remainder)), pow_mod256(1000, remainder))

    # Since we have chosen good initial values for the cube roots, 7 Newton-Raphson
    # iterations are just sufficient. 6 iterations would lead to non-convergences,
    # and 8 would be one iteration too many. Without initial values, the iteration
    # number can be up to 20 or more. The iterations are unrolled. This reduces the
    # gas cost, but requires more bytecode.
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(xx, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(xx, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(xx, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(xx, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(xx, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(xx, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(xx, unsafe_mul(y, y))), 3)

    # Since we scaled up, we have to scale down accordingly.
    if (x >= unsafe_mul(unsafe_div(max_value(uint256), 10 ** 36), 10 ** 18)):
        return unsafe_mul(y, 10 ** 12)
    elif x >= unsafe_div(max_value(uint256), 10 ** 36):
        return unsafe_mul(y, 10 ** 6)
    else:
        return y
