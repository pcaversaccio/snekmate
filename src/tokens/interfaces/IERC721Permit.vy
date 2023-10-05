# pragma version ^0.3.10
"""
@title EIP-4494 Interface Definition
@custom:contract-name IERC721Permit
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The `permit` function implements approvals via
        EIP-712 secp256k1 signatures for ERC-721 tokens:
        https://eips.ethereum.org/EIPS/eip-4494. The
        `permit` function allows users to modify the
        permission of who can manage a `tokenId` using
        a signed message (via secp256k1 signatures),
        instead of through `msg.sender`. By not relying
        on `approve`, the token holder's account does not
        need to send a transaction and therefore does not
        need to hold ether, enabling important use cases
        such as meta-transactions.

        IMPORTANT: Due to sake of consistency, we follow EIP-2612's
        pattern (see https://eips.ethereum.org/EIPS/eip-2612) and
        implement the `permit` function via the secp256k1 signature
        parameters `v`, `r`, and `s` and do not support EIP-2098
        signatures (64-byte length, see https://eips.ethereum.org/EIPS/eip-2098).
        The ERC-165 identifier for this interface is `0x589C5CE2`.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


@external
@view
def supportsInterface(interfaceId: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interfaceId`.
    @notice For more details on how these identifiers are
            created, please refer to:
            https://eips.ethereum.org/EIPS/eip-165.
    @param interfaceId The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return empty(bool)


@external
def permit(spender: address, tokenId: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32):
    """
    @dev Sets permission to `spender` to transfer `tokenId`
         token to another account, given `owner`'s signed
         approval.
    @notice Note that `spender` cannot be the zero address.
            Also, `deadline` must be a block timestamp in
            the future. `v`, `r`, and `s` must be a valid
            secp256k1 signature from `owner` over the
            EIP-712-formatted function arguments. Eventually,
            the signature must use `tokenId`'s current nonce.
    @param spender The 20-byte spender address.
    @param tokenId The 32-byte identifier of the token.
    @param deadline The 32-byte block timestamp up
           which the `spender` is allowed to spend `tokenId`.
    @param v The secp256k1 1-byte signature parameter `v`.
    @param r The secp256k1 32-byte signature parameter `r`.
    @param s The secp256k1 32-byte signature parameter `s`.
    """
    pass


@external
@view
def nonces(tokenId: uint256) -> uint256:
    """
    @dev Returns the current on-chain tracked nonce of `tokenId`.
    @param tokenId The 32-byte identifier of the token.
    @return uint256 The 32-byte `tokenId` nonce.
    """
    return empty(uint256)


@external
@view
def DOMAIN_SEPARATOR() -> bytes32:
    """
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    return empty(bytes32)
