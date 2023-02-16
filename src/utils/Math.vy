# @version ^0.3.7
"""
@title Standard Mathematical Utility Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


@external
@pure
def _mul_div(x: uint256, y: uint256, denominator: uint256, rounding: Rounding) -> uint256:
    """
    @dev TBD
    """
    prod0: uint256 = empty(uint256)
    prod1: uint256 = empty(uint256)

    mm: uint256 = uint256_mulmod(x, y, ~empty(uint256))
    prod0 = unsafe_mul(x, y)
    if (mm < prod0):
        prod1 = unsafe_sub(unsafe_sub(mm, prod0), 1)
    else:
        prod1 = unsafe_sub(mm, prod0)

    if (prod1 == empty(uint256)):
        return unsafe_div(prod0, denominator)

    assert denominator > prod1, "Math: mul_div overflow"

    remainder: uint256 = uint256_mulmod(x, y, denominator)
    if (remainder > prod0):
        prod1 = unsafe_sub(prod1, 1)
    else:
        prod0 = unsafe_sub(prod0, remainder)

    twos: uint256 = denominator & (unsafe_add(~denominator, 1))
    denominator_div: uint256 = unsafe_div(denominator, twos)
    prod0 = unsafe_div(prod0, twos)
    twos = unsafe_add(unsafe_div(unsafe_sub(empty(uint256), twos), twos), 1)

    prod0 |= unsafe_mul(prod1, twos)

    inverse: uint256 = unsafe_mul(3, denominator_div) ^ 2
    
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^8
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^16
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^32
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^64
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^128
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^256

    result: uint256 = unsafe_mul(prod0, inverse)

    if (rounding == Rounding.UP and uint256_mulmod(x, y, denominator) > 0):
        return unsafe_add(result, 1)
    else:
        return result