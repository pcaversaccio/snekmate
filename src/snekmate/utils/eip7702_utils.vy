# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title EIP-7702 Utility Functions
@custom:contract-name eip7702_utils
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to interact with accounts that conform
        to the EIP-7702 (https://eips.ethereum.org/EIPS/eip-7702) specification.
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/account/utils/EIP7702Utils.sol.
"""


# @dev The 3-byte EIP-7702 delegation prefix.
_DELEGATION_PREFIX: constant(bytes3) = 0xef0100


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
@view
def _fetch_delegate(account: address) -> address:
    """
    @dev Returns the current EIP-7702 delegation contract
         for `account` if one has been set via a set code
         transaction, or the zero address `empty(address)`
         otherwise.
    @notice Note that an `account` can revoke its delegation
            at any time by setting the delegation contract to
            the zero address `empty(address)` via a set code
            transaction. However, this does not delete the
            `account`'s storage, which remains intact.
    @param account The 20-byte account address.
    @return address The 20-byte delegation contract address.
    """
    # For the special case where the code size is less than 23 bytes,
    # we already return `empty(address)` here in order not to iterate
    # through the remaining code.
    if account.codesize < 23:
        return empty(address)

    # Per EIP-7702, the delegation indicator is 23 bytes long, consisting
    # of the prefix `0xef0100` followed by the 20-byte delegation address.
    delegation: Bytes[23] = slice(account.code, 0, 23)
    delegation_bytes32: bytes32 = convert(delegation, bytes32)

    if convert(convert(delegation_bytes32 >> 232, uint24), bytes3) != _DELEGATION_PREFIX:
        return empty(address)

    return convert(convert(convert(delegation_bytes32 << 24, bytes20), uint160), address)
