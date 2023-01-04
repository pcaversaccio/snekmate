# @version ^0.3.7
"""
@title Base64 Encoding and Decoding Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions can be used to encode bytes or to decode strings
        using the Base64 binary-to-text encoding scheme. For more details,
        please refer to: https://www.rfc-editor.org/rfc/rfc4648#section-4.
        The implementation is inspired by Brecht Devos' implementation here:
        https://github.com/Brechtpd/base64/blob/main/base64.sol,
        as well as by horsefacts' implementation here:
        https://github.com/horsefacts/commit-reveal/blob/main/contracts/Base64.vy.
"""


# @dev Sets the maximum input and output length
# allowed. For an n-byte input to be encoded, the
# space required for the Base64-encoded content
# (without line breaks) is "4 * ceil(n/3)" characters.
_DATA_INPUT_BOUND: constant(uint256) = 1024
_DATA_OUTPUT_BOUND: constant(uint256) = 1368


# @dev Defines the Base64 encoding tables. For encoding
# with a URL and filename-safe alphabet, please refer to:
# https://www.rfc-editor.org/rfc/rfc4648#section-5.
_TABLE_STD_CHARS: constant(String[65]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
_TABLE_URL_CHARS: constant(String[65]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="


@external
@pure
def encode(data: Bytes[_DATA_INPUT_BOUND], base64_url: bool) -> DynArray[String[4], _DATA_OUTPUT_BOUND]:
    """
    @dev Encodes a `Bytes` array using the Base64
         binary-to-text encoding scheme.
    @notice Due to the Vyper design with fixed-size
            string parameters, string concatenations
            with itself in a loop can lead to length
            mismatches (the underlying issue is that
            Vyper does not support a mutable `Bytes`
            type). To circumvent this issue, we choose
            a dynamic array as the return type.
    @param data The maximum 1024-byte data to be
           Base64-encoded.
    @param base64_url The Boolean variable that specifies
           whether to use a URL and filename-safe alphabet
           or not.
    @return DynArray The maximum 4-character user-readable
            string array that combined results in the Base64
            encoding of `data`.
    """
    data_length: uint256 = len(data)
    if (data_length == empty(uint256)):
        return empty(DynArray[String[4], 1])

    # If the length of the unencoded input is not
    # a multiple of three, the encoded output must
    # have padding added so that its length is a
    # multiple of four.
    padding: uint256 = data_length % 3
    data_padded: Bytes[_DATA_INPUT_BOUND + 2] = b""
    if (padding == 1):
        data_padded = concat(data, b"\x00\x00")
    elif (padding == 2):
        data_padded = concat(data, b"\x00")
    else:
        data_padded = data

    char_chunks: DynArray[String[4], _DATA_OUTPUT_BOUND] = []
    idx: uint256 = 0
    for _ in range(_DATA_INPUT_BOUND):
        # For the Base64 encoding, three bytes (= chunk)
        # of the bytestream (= 24 bits) are divided into
        # four 6-bit blocks.
        chunk: uint256 = convert(slice(data_padded, idx, 3), uint256)

        # To write each character, we right shift the 3-byte
        # chunk (= 24 bits) four times in blocks of six bits
        # for each character (18, 12, 6, 0).
        c1: uint256 = shift(chunk, -18) & 63
        c2: uint256 = shift(chunk, -12) & 63
        c3: uint256 = shift(chunk, -6) & 63
        c4: uint256 = chunk & 63

        # Base64 encoding with an URL and filename-safe alphabet.
        if (base64_url):
            char_chunks.append(concat(slice(_TABLE_URL_CHARS, c1, 1), slice(_TABLE_URL_CHARS, c2, 1), slice(_TABLE_URL_CHARS, c3, 1),\
                                      slice(_TABLE_URL_CHARS, c4, 1)))
        # Base64 encoding using the standard characters.
        else:
            char_chunks.append(concat(slice(_TABLE_STD_CHARS, c1, 1), slice(_TABLE_STD_CHARS, c2, 1), slice(_TABLE_STD_CHARS, c3, 1),\
                                      slice(_TABLE_STD_CHARS, c4, 1)))

        # The following line cannot overflow because we have
        # limited the for loop by the `constant` parameter
        # `_DATA_INPUT_BOUND`, which is bounded by the
        # maximum value of `1024`.
        idx = unsafe_add(idx, 3)

        # We break the loop once we reach the end of `data`
        # (including padding).
        if (idx == len(data_padded)):
            break

    # Case 1: padding of "==" added.
    if (padding == 1):
        last_chunk: String[2] = slice(char_chunks.pop(), 0, 2)
        char_chunks.append(concat(last_chunk, "=="))
    # Case 2: padding of "=" added.
    elif (padding == 2):
        last_chunk: String[3] = slice(char_chunks.pop(), 0, 3)
        char_chunks.append(concat(last_chunk, "="))

    return char_chunks


@external
@pure
def decode(data: String[_DATA_OUTPUT_BOUND], base64_url: bool) -> DynArray[Bytes[3], _DATA_INPUT_BOUND]:
    """
    @dev TBD
    """
    data_length: uint256 = len(data)
    if (data_length == empty(uint256)):
        return empty(DynArray[Bytes[3], _DATA_INPUT_BOUND])

    assert data_length % 4 == 0, "Base64: length mismatch"

    result: DynArray[Bytes[3], _DATA_INPUT_BOUND] = []
    idx: uint256 = 0
    for _ in range(_DATA_OUTPUT_BOUND):
        chunk: String[4] = slice(data, idx, 4)

        if (base64_url):
            c1: uint256 = self._index_of(slice(chunk, 0, 1), True)
            c2: uint256 = self._index_of(slice(chunk, 1, 1), True)
            c3: uint256 = self._index_of(slice(chunk, 2, 1), True)
            c4: uint256 = self._index_of(slice(chunk, 3, 1), True)

            chunk_bytes: uint256 = shift(c1, 18) | shift(c2, 12) | shift(c3, 6) | c4

            b1: bytes1 = convert(convert(shift(chunk_bytes, -16) & 255, uint8), bytes1)
            b2: bytes1 = convert(convert(shift(chunk_bytes, -8) & 255, uint8), bytes1)
            b3: bytes1 = convert(convert(chunk_bytes & 255, uint8), bytes1)

            if (c4 == 64):
                result.append(concat(b1, b2, b"\x00"))
            elif (c3 == 63):
                result.append(concat(b1, b"\x00\x00"))
            else:
                result.append(concat(b1, b2, b3))

            idx = unsafe_add(idx, 4)

            if (idx == data_length):
                break
        else:
            c1: uint256 = self._index_of(slice(chunk, 0, 1), False)
            c2: uint256 = self._index_of(slice(chunk, 1, 1), False)
            c3: uint256 = self._index_of(slice(chunk, 2, 1), False)
            c4: uint256 = self._index_of(slice(chunk, 3, 1), False)

            chunk_bytes: uint256 = shift(c1, 18) | shift(c2, 12) | shift(c3, 6) | c4

            b1: bytes1 = convert(convert(shift(chunk_bytes, -16) & 255, uint8), bytes1)
            b2: bytes1 = convert(convert(shift(chunk_bytes, -8) & 255, uint8), bytes1)
            b3: bytes1 = convert(convert(chunk_bytes & 255, uint8), bytes1)

            if (c4 == 64):
                result.append(concat(b1, b2, b"\x00"))
            elif (c3 == 63):
                result.append(concat(b1, b"\x00\x00"))
            else:
                result.append(concat(b1, b2, b3))

            idx = unsafe_add(idx, 4)

            if (idx == data_length):
                break

    return result


@internal
@pure
def _index_of(char: String[1], base64_url: bool) -> uint256:
    pos: uint256 = 0
    for _ in range(len(_TABLE_URL_CHARS)):
        if (base64_url):
            if (char == slice(_TABLE_URL_CHARS, pos, 1)):
                break
        else:
            if (char == slice(_TABLE_STD_CHARS, pos, 1)):
                break
        pos = unsafe_add(pos, 1)
    assert pos < len(_TABLE_URL_CHARS), "Base64: invalid string"
    return pos
