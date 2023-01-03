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
# (without line breaks) is 4 * ceil(n/3) characters.
_DATA_INPUT_BOUND: constant(uint256) = 1024
_DATA_OUTPUT_BOUND: constant(uint256) = 1368


# @dev Defines the Base64 encoding table. For encoding
# with a URL and filename-safe alphabet, please refer to:
# https://www.rfc-editor.org/rfc/rfc4648#section-5.
_TABLE_STD_CHARS: constant(String[64]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
_TABLE_URL_CHARS: constant(String[64]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"


@external
@pure
def encode(data: Bytes[_DATA_INPUT_BOUND], base64_url: bool) -> DynArray[String[4], _DATA_OUTPUT_BOUND]:
    """
    @dev Encodes a `Bytes` array using the Base64
         binary-to-text encoding scheme.
    @notice Due to the Vyper design with fixed-size
            string parameters, string concatenations
            in a loop can lead to length mismatches.
            To circumvent this issue, we choose a
            dynamic array as the return type.  
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

        # To write each character, we shift the 3-byte chunk
        # (= 24 bits) four times in blocks of six bits for
        # each character (18, 12, 6, 0).
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
        if idx == len(data_padded):
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
def decode(data: String[1368]) -> Bytes[1024]:
    """
    @dev TBD
    """
    return empty(Bytes[1024])
