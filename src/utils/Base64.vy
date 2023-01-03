# @version ^0.3.7
"""
@title Base64 Encoding and Decoding Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions can be used to encode bytes or to decode strings
        using the Base64 binary-to-text encoding scheme. The implementation
        is inspired by Brecht Devos' implementation here:
        https://github.com/Brechtpd/base64/blob/main/base64.sol.
"""


_TABLE_STD_CHARS: constant(String[64]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
_TABLE_URL_CHARS: constant(String[64]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"


@external
@pure
def encode(data: Bytes[1024], base64_url: bool) -> String[1368]:
    """
    @dev TBD
    @notice TBD
    @param data TBD
    @param base64_url TBD
    @return String TBD
    """
    data_length: uint256 = len(data)
    if (data_length == empty(uint256)):
        return ""

    # The following line cannot overflow because we have
    # bounded the dynamic array `data` by the maximum value
    # of `1024`, which in turn would allow a maximum `encoded_length`
    # of `1368`.
    encoded_length: uint256 = unsafe_mul(unsafe_div(unsafe_add(data_length, 2), 3), 4)
    result: String[1368] = ""

    idx_1: uint256 = 0
    idx_2: uint256 = 0
    for _ in range(1024):
        chunk: uint256 = convert(slice(result, idx_1, 3), uint256)

        c1: uint256 = shift(chunk, -18) & 63
        c2: uint256 = shift(chunk, -12) & 63
        c3: uint256 = shift(chunk, -6) & 63
        c4: uint256 = chunk & 63

        result[idx_2] = slice(_TABLE_STD_CHARS, c1, 1)
        result[idx_2 + 1] = slice(_TABLE_STD_CHARS, c2, 1)
        result[idx_2 + 2] = slice(_TABLE_STD_CHARS, c3, 1)
        result[idx_2 + 3] = slice(_TABLE_STD_CHARS, c4, 1)
        
        idx_1 = unsafe_add(idx_1, 3)

        if idx_1 == encoded_length:
            break

    return result

@external
@pure
def decode(data: String[1368]) -> Bytes[1024]:
    """
    @dev TBD
    """
    return empty(Bytes[1024])
