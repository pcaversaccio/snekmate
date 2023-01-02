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
    """
    data_length: uint256 = len(data)

    if(data_length == empty(uint256)):
        return ""
    
    return empty(String[1368])
    


@external
@pure
def decode(data: String[1368]) -> Bytes[1024]:
    """
    @dev TBD
    """
    return empty(Bytes[1024])
