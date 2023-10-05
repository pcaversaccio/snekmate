# pragma version ^0.3.10
"""
@title EIP-2612 Interface Definition
@custom:contract-name IERC20Permit
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The `permit` function implements approvals via
        EIP-712 secp256k1 signatures:
        https://eips.ethereum.org/EIPS/eip-2612.
        The `permit` function allows users to modify
        the allowance mapping using a signed message
        (via secp256k1 signatures), instead of through
        `msg.sender`. By not relying on `approve`,
        the token holder's account does not need to
        send a transaction and therefore does not need
        to hold ether, enabling important use cases such
        as meta-transactions.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


@external
def permit(owner: address, spender: address, amount: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32):
    """
    @dev Sets `amount` as the allowance of `spender`
         over `owner`'s tokens, given `owner`'s signed
         approval.
    @notice Note that `spender` cannot be the zero address.
            Also, `deadline` must be a block timestamp in
            the future. `v`, `r`, and `s` must be a valid
            secp256k1 signature from `owner` over the
            EIP-712-formatted function arguments. Eventually,
            the signature must use `owner`'s current nonce.
    @param owner The 20-byte owner address.
    @param spender The 20-byte spender address.
    @param amount The 32-byte token amount that is
           allowed to be spent by the `spender`.
    @param deadline The 32-byte block timestamp up
           which the `spender` is allowed to spend `amount`.
    @param v The secp256k1 1-byte signature parameter `v`.
    @param r The secp256k1 32-byte signature parameter `r`.
    @param s The secp256k1 32-byte signature parameter `s`.
    """
    pass


@external
@view
def nonces(owner: address) -> uint256:
    """
    @dev Returns the current on-chain tracked nonce of `owner`.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte owner nonce.
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
