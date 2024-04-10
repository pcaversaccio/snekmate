# pragma version ~=0.4.0b6
"""
@title Base64 Module Reference Implementation
@custom:contract-name Base64Mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `Base64` module.
# @notice Please note that the `Base64` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import Base64 as b64


@deploy
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
def encode(data: Bytes[b64._DATA_INPUT_BOUND], base64_url: bool) -> DynArray[String[4], b64._DATA_OUTPUT_BOUND]:
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
    return b64._encode(data, base64_url)


@external
@pure
def decode(data: String[b64._DATA_OUTPUT_BOUND], base64_url: bool) -> DynArray[Bytes[3], b64._DATA_INPUT_BOUND]:
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
    return b64._decode(data, base64_url)
