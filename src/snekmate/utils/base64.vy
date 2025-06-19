# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Base64 Encoding and Decoding Functions
@custom:contract-name base64
@license GNU Affero General Public License v3.0 only
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
_DATA_INPUT_BOUND: constant(uint256) = 1_024
_DATA_OUTPUT_BOUND: constant(uint256) = 1_368


# @dev Defines the Base64 encoding tables. For encoding
# with a URL and filename-safe alphabet, please refer to:
# https://www.rfc-editor.org/rfc/rfc4648#section-5.
_TABLE_STD_CHARS: constant(String[65]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
_TABLE_URL_CHARS: constant(String[65]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@internal
@pure
def _encode(data: Bytes[_DATA_INPUT_BOUND], base64_url: bool) -> DynArray[String[4], _DATA_OUTPUT_BOUND]:
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
    @param data The maximum 1,024-byte data to be
           Base64-encoded.
    @param base64_url The Boolean variable that specifies
           whether to use a URL and filename-safe alphabet
           or not.
    @return DynArray The maximum 4-character user-readable
            string array that combined results in the Base64
            encoding of `data`.
    """
    data_length: uint256 = len(data)
    if data_length == empty(uint256):
        return empty(DynArray[String[4], _DATA_OUTPUT_BOUND])

    # If the length of the unencoded input is not
    # a multiple of three, the encoded output must
    # have padding added so that its length is a
    # multiple of four.
    padding: uint256 = data_length % 3
    data_padded: Bytes[_DATA_INPUT_BOUND + 2] = b""
    if padding == 1:
        data_padded = concat(data, x"0000")
    elif padding == 2:
        data_padded = concat(data, x"00")
    else:
        data_padded = data

    char_chunks: DynArray[String[4], _DATA_OUTPUT_BOUND] = []
    idx: uint256 = empty(uint256)
    for _: uint256 in range(_DATA_INPUT_BOUND):
        # For the Base64 encoding, three bytes (= chunk)
        # of the bytestream (= 24 bits) are divided into
        # four 6-bit blocks.
        chunk: uint256 = convert(slice(data_padded, idx, 3), uint256)

        # To write each character, we right shift the 3-byte
        # chunk (= 24 bits) four times in blocks of six bits
        # for each character (18, 12, 6, 0). Note that masking
        # is not required for the first part of the block, as
        # 6 bits are already extracted when the chunk is shifted
        # to the right by 18 bits (out of 24 bits). To illustrate
        # why, here is an example:
        # Example case for `c1`:
        #   6bit   6bit   6bit   6bit
        # │------│------│------│------│
        #  011100 000111 100101 110100
        #
        # `>> 18` (right shift `c1` by 18 bits)
        #   6bit   6bit   6bit   6bit
        # │------│------│------│------│
        #  000000 000000 000000 011100
        #
        # 63 (or `0x3F`) is `000000000000000000111111` in binary.
        # Thus, the bitwise `AND` operation is redundant.
        c1: uint256 = chunk >> 18
        c2: uint256 = (chunk >> 12) & 63
        c3: uint256 = (chunk >> 6) & 63
        c4: uint256 = chunk & 63

        # Base64 encoding with an URL and filename-safe
        # alphabet.
        if base64_url:
            char_chunks.append(
                concat(
                    slice(_TABLE_URL_CHARS, c1, 1),
                    slice(_TABLE_URL_CHARS, c2, 1),
                    slice(_TABLE_URL_CHARS, c3, 1),
                    slice(_TABLE_URL_CHARS, c4, 1),
                )
            )
        # Base64 encoding using the standard characters.
        else:
            char_chunks.append(
                concat(
                    slice(_TABLE_STD_CHARS, c1, 1),
                    slice(_TABLE_STD_CHARS, c2, 1),
                    slice(_TABLE_STD_CHARS, c3, 1),
                    slice(_TABLE_STD_CHARS, c4, 1),
                )
            )

        # The following line cannot overflow because we have
        # limited the for loop by the `constant` parameter
        # `_DATA_INPUT_BOUND`, which is bounded by the
        # maximum value of `1_024`.
        idx = unsafe_add(idx, 3)

        # We break the loop once we reach the end of `data`
        # (including padding).
        if idx == len(data_padded):
            break

    # Case 1: padding of "==" added.
    if padding == 1:
        last_chunk: String[2] = slice(char_chunks.pop(), empty(uint256), 2)
        char_chunks.append(concat(last_chunk, "=="))
    # Case 2: padding of "=" added.
    elif padding == 2:
        last_chunk: String[3] = slice(char_chunks.pop(), empty(uint256), 3)
        char_chunks.append(concat(last_chunk, "="))

    return char_chunks


@internal
@pure
def _decode(data: String[_DATA_OUTPUT_BOUND], base64_url: bool) -> DynArray[Bytes[3], _DATA_INPUT_BOUND]:
    """
    @dev Decodes a `String` input using the Base64
         binary-to-text encoding scheme.
    @notice Due to the Vyper design with fixed-size
            byte parameters, byte concatenations
            with itself in a loop can lead to length
            mismatches (the underlying issue is that
            Vyper does not support a mutable `Bytes`
            type). To circumvent this issue, we choose
            a dynamic array as the return type. Note
            that line breaks are not supported.
    @param data The maximum 1,368-byte data to be
           Base64-decoded.
    @param base64_url The Boolean variable that specifies
           whether to use a URL and filename-safe alphabet
           or not.
    @return DynArray The maximum 3-byte array that combined
            results in the Base64 decoding of `data`.
    """
    data_length: uint256 = len(data)
    if data_length == empty(uint256):
        return empty(DynArray[Bytes[3], _DATA_INPUT_BOUND])

    # If the length of the encoded input is not a
    # multiple of four, it is an invalid input.
    assert data_length % 4 == empty(uint256), "base64: length mismatch"

    result: DynArray[Bytes[3], _DATA_INPUT_BOUND] = []
    idx: uint256 = empty(uint256)
    for _: uint256 in range(_DATA_OUTPUT_BOUND):
        # Each of these four characters represents
        # a 6-bit index in the Base64 character list
        # which, when concatenated, gives the 24-bit
        # number for the original three characters.
        chunk: String[4] = slice(data, idx, 4)

        # Base64 encoding with an URL and filename-safe
        # alphabet.
        if base64_url:
            c1: uint256 = self._index_of(slice(chunk, empty(uint256), 1), True)
            c2: uint256 = self._index_of(slice(chunk, 1, 1), True)
            c3: uint256 = self._index_of(slice(chunk, 2, 1), True)
            c4: uint256 = self._index_of(slice(chunk, 3, 1), True)

            # We concatenate the 6-bit index in the Base64
            # character list, which gives the 24-bit number
            # for the original three characters.
            chunk_bytes: uint256 = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4

            # We split the 24-bit number into the original
            # three 8-bit characters.
            b1: bytes1 = convert(convert((chunk_bytes >> 16) & 255, uint8), bytes1)
            b2: bytes1 = convert(convert((chunk_bytes >> 8) & 255, uint8), bytes1)
            b3: bytes1 = convert(convert(chunk_bytes & 255, uint8), bytes1)

            # Case 1: padding of "=" as part of the
            # encoded input.
            if c4 == 64:
                result.append(concat(b1, b2, x"00"))
            # Case 2: padding of "==" as part of the
            # encoded input.
            elif c3 == 63:
                result.append(concat(b1, x"0000"))
            # Case 3: no padding as part of the encoded
            # input.
            else:
                result.append(concat(b1, b2, b3))

            # The following line cannot overflow because we have
            # limited the for loop by the `constant` parameter
            # `_DATA_OUTPUT_BOUND`, which is bounded by the
            # maximum value of `1_368`.
            idx = unsafe_add(idx, 4)

            # We break the loop once we reach the end of `data`.
            if idx == data_length:
                break
        # Base64 encoding using the standard characters.
        else:
            c1: uint256 = self._index_of(slice(chunk, empty(uint256), 1), False)
            c2: uint256 = self._index_of(slice(chunk, 1, 1), False)
            c3: uint256 = self._index_of(slice(chunk, 2, 1), False)
            c4: uint256 = self._index_of(slice(chunk, 3, 1), False)

            chunk_bytes: uint256 = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4

            # We split the 24-bit number into the original
            # three 8-bit characters.
            b1: bytes1 = convert(convert((chunk_bytes >> 16) & 255, uint8), bytes1)
            b2: bytes1 = convert(convert((chunk_bytes >> 8) & 255, uint8), bytes1)
            b3: bytes1 = convert(convert(chunk_bytes & 255, uint8), bytes1)

            # Case 1: padding of "=" as part of the
            # encoded input.
            if c4 == 64:
                result.append(concat(b1, b2, x"00"))
            # Case 2: padding of "==" as part of the
            # encoded input.
            elif c3 == 63:
                result.append(concat(b1, x"0000"))
            # Case 3: no padding as part of the encoded
            # input.
            else:
                result.append(concat(b1, b2, b3))

            # The following line cannot overflow because we have
            # limited the for loop by the `constant` parameter
            # `_DATA_OUTPUT_BOUND`, which is bounded by the
            # maximum value of `1_368`.
            idx = unsafe_add(idx, 4)

            # We break the loop once we reach the end of `data`.
            if idx == data_length:
                break

    return result


@internal
@pure
def _index_of(char: String[1], base64_url: bool) -> uint256:
    """
    @dev Returns the index position of the string `char`
         in the Base64 encoding table(s).
    @param char The maximum 1-character user-readable string.
    @param base64_url The Boolean variable that specifies
           whether to use a URL and filename-safe alphabet
           or not.
    @return uint256 The 32-byte index position of the string
            `char` in the Base64 encoding table.
    """
    pos: uint256 = empty(uint256)
    for _: uint256 in range(len(_TABLE_URL_CHARS)):
        # Base64 encoding with an URL and filename-safe
        # alphabet.
        if base64_url:
            if char == slice(_TABLE_URL_CHARS, pos, 1):
                break
        # Base64 encoding using the standard characters.
        else:
            if char == slice(_TABLE_STD_CHARS, pos, 1):
                break

        # The following line cannot overflow because we have
        # limited the for loop by the `constant` parameter
        # `_TABLE_URL_CHARS`, which is bounded by the
        # maximum value of `65`.
        pos = unsafe_add(pos, 1)

    # If no matching character is found, it is an
    # invalid input.
    assert pos < len(_TABLE_URL_CHARS), "base64: invalid string"

    return pos
