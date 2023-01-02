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


_TABLE: constant(String[64]) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


#@external
#@pure
#def encode(data: Bytes[1024], base64_url: bool) -> 
