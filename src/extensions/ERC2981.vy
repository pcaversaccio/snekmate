# pragma version ^0.3.10
"""
@title ERC-721 and ERC-1155 Compatible ERC-2981 Reference Implementation
@custom:contract-name ERC2981
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice Reference implementation of the non-fungible token (NFT) royalty
        standard EIP-2981 (https://eips.ethereum.org/EIPS/eip-2981), a
        standardised way to retrieve on-chain royalty payment information.
        This implementation can be seamlessly integrated into an ERC-721 or
        ERC-1155 contract. The royalty information can be specified globally
        for all token IDs via the access-restricted function `set_default_royalty`,
        and/or individually for specific token IDs via the access-restricted
        function `set_token_royalty`. The latter takes precedence over the
        first. Furthermore, the royalty is specified as a fraction of the sale
        price. The `internal` state variable `_fee_denominator` defaults to
        `10_000`, meaning the fee is specified in basis points by default.

        IMPORTANT: The ERC-2981 standard only specifies a way to signal royalty
        information and does not enforce its payment:
        https://eips.ethereum.org/EIPS/eip-2981#rationale.
        Marketplaces are expected to voluntarily pay royalties together with sales,
        but note that this standard is not yet widely supported.

        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol.
@custom:security If you integrate this contract with an ERC-721 contract, please
                 consider clearing the royalty information from storage on calling
                 `burn` (to avoid any NatSpec parsing error, no `@` character is added
                 to the visibility decorator `@internal` in the following example;
                 please add it accordingly):
                 ```vy
                 internal
                 def _burn(token_id: uint256):
                     ...
                     self._reset_token_royalty(token_id)
                 ```

                 Due to the fungibility of ERC-1155 tokens, the implementation of
                 this mechanism with ERC-1155 tokens is not recommended.
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `IERC2981` interface,
# which is written using standard Vyper syntax.
import interfaces.IERC2981 as IERC2981
implements: IERC2981


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
# @notice If you are integrating this contract with an
# ERC-721 or ERC-1155 contract, please ensure you include
# the additional ERC-165 interface identifiers.
_SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0x2A55205A, # The ERC-165 identifier for ERC-2981.
]


# @dev Returns the address of the current owner.
owner: public(address)


# @dev Tightly packed royalty information struct. Note that
# Vyper does not currently support tight packing, but will
# do so in the near future.
struct RoyaltyInfo:
    receiver: address
    royalty_fraction: uint96


# @dev Default royalty information struct.
_default_royalty_info: RoyaltyInfo


# @dev Mapping from token ID to the `RoyaltyInfo` struct.
_token_royalty_info: HashMap[uint256, RoyaltyInfo]


# @dev The denominator with which to interpret the fee set
# in `_set_token_royalty` and `_set_default_royalty` as a
# fraction of the sale price. Defaults to `10_000` so fees
# are expressed in basis points.
_fee_denominator: uint256


# @dev Emitted when the ownership is transferred
# from `previous_owner` to `new_owner`.
event OwnershipTransferred:
    previous_owner: indexed(address)
    new_owner: indexed(address)


@external
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice We set the default value of `_fee_denominator`
            to `10_000` so that the fee is in basis points by
            default. Also, the `owner` role will be assigned
            to the `msg.sender`.

            IMPORTANT: The `_default_royalty_info` is set to
            the EVM default values `receiver = empty(address)`
            and `royalty_fraction = empty(uint96)`. If you want
            to set your own default values during contract creation,
            you can call `self._default_royalty(receiver, fee_numerator)`
            in the constructor.
    """
    self._fee_denominator = 10_000
    self._transfer_ownership(msg.sender)


@external
@view
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interface_id`.
    @param interface_id The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    return interface_id in _SUPPORTED_INTERFACES


@external
@view
def royaltyInfo(token_id: uint256, sale_price: uint256) -> (address, uint256):
    """
    @dev Returns how much royalty is owed and to whom, based
         on a sale price that may be denominated in any unit
         of exchange. The royalty amount is denominated and
         should be paid in that same unit of exchange.
    @param token_id The 32-byte identifier of the token.
    @param sale_price The 32-byte sale price of the NFT asset
           specified by `token_id`.
    @return address The 20-byte address of the recipient of
            the royalty payment.
    @return uint256 The 32-byte royalty payment amount for
            `sale_price`.
    """
    royalty: RoyaltyInfo = self._token_royalty_info[token_id]
    if (royalty.receiver == empty(address)):
        royalty = self._default_royalty_info

    # The following line uses intentionally checked arithmetic to
    # prevent a theoretically possible overflow.
    royalty_amount: uint256 = (sale_price * convert(royalty.royalty_fraction, uint256)) / self._fee_denominator

    return (royalty.receiver, royalty_amount)


@external
def set_default_royalty(receiver: address, fee_numerator: uint96):
    """
    @dev Sets the royalty information that all IDs in this
         contract will default to. This function can only be
         called by the current `owner`.
    @notice Note that the `receiver` cannot be the zero address.
            Also, `fee_numerator` cannot be greater than the fee
            denominator.
    @param receiver The 20-byte address of the recipient of
           the royalty payment.
    @param fee_numerator The 12-byte fee numerator used to calculate
           the royalty fraction.
    """
    self._check_owner()
    self._set_default_royalty(receiver, fee_numerator)


@external
def delete_default_royalty():
    """
    @dev Removes the default royalty information. This function can only
         be called by the current `owner`.
    """
    self._check_owner()
    self._delete_default_royalty()


@external
def set_token_royalty(token_id: uint256, receiver: address, fee_numerator: uint96):
    """
    @dev Sets the royalty information for a specific token ID,
         overriding the global default. This function can only
         be called by the current `owner`.
    @notice Note that the `receiver` cannot be the zero address.
            Also, `fee_numerator` cannot be greater than the fee
            denominator.
    @param token_id The 32-byte identifier of the token.
    @param receiver The 20-byte address of the recipient of
           the royalty payment.
    @param fee_numerator The 12-byte fee numerator used to calculate
           the royalty fraction.
    """
    self._check_owner()
    self._set_token_royalty(token_id, receiver, fee_numerator)


@external
def reset_token_royalty(token_id: uint256):
    """
    @dev Resets the royalty information for the token ID back to
         the global default. This function can only be called by
         the current `owner`.
    @param token_id The 32-byte identifier of the token.
    """
    self._check_owner()
    self._reset_token_royalty(token_id)


@external
def transfer_ownership(new_owner: address):
    """
    @dev Sourced from {Ownable-transfer_ownership}.
    @notice See {Ownable-transfer_ownership} for
            the function docstring.
    @custom:security If you integrate this implementation into an
                     ERC-721 or ERC-1155 contract that implements
                     an `is_minter` role, ensure that the previous
                     owner's minter role is also removed and the
                     minter role is assigned to the `new_owner`
                     accordingly.
    """
    self._check_owner()
    assert new_owner != empty(address), "Ownable: new owner is the zero address"
    self._transfer_ownership(new_owner)


@external
def renounce_ownership():
    """
    @dev Sourced from {Ownable-renounce_ownership}.
    @notice See {Ownable-renounce_ownership} for
            the function docstring.
    @custom:security If you integrate this implementation into an
                     ERC-721 or ERC-1155 contract that implements
                     an `is_minter` role, ensure that the previous
                     owner's minter role as well as all non-owner
                     minter addresses are also removed before calling
                     `renounce_ownership`.
    """
    self._check_owner()
    self._transfer_ownership(empty(address))


@internal
def _set_default_royalty(receiver: address, fee_numerator: uint96):
    """
    @dev Sets the royalty information that all IDs in this
         contract will default to.
    @notice This is an `internal` function without access restriction.
            Note that the `receiver` cannot be the zero address.
            Also, `fee_numerator` cannot be greater than the fee
            denominator.
    @param receiver The 20-byte address of the recipient of
           the royalty payment.
    @param fee_numerator The 12-byte fee numerator used to calculate
           the royalty fraction.
    """
    denominator: uint256 = self._fee_denominator
    assert convert(fee_numerator, uint256) <= denominator, "ERC2981: royalty fee will exceed sale_price"
    assert receiver != empty(address), "ERC2981: invalid receiver"
    self._default_royalty_info = RoyaltyInfo({receiver: receiver, royalty_fraction: fee_numerator})


@internal
def _delete_default_royalty():
    """
    @dev Removes the default royalty information.
    @notice This is an `internal` function without access restriction.
    """
    self._default_royalty_info = RoyaltyInfo({receiver: empty(address), royalty_fraction: empty(uint96)})


@internal
def _set_token_royalty(token_id: uint256, receiver: address, fee_numerator: uint96):
    """
    @dev Sets the royalty information for a specific token ID,
         overriding the global default.
    @notice This is an `internal` function without access restriction.
            Note that the `receiver` cannot be the zero address.
            Also, `fee_numerator` cannot be greater than the fee
            denominator.
    @param token_id The 32-byte identifier of the token.
    @param receiver The 20-byte address of the recipient of
           the royalty payment.
    @param fee_numerator The 12-byte fee numerator used to calculate
           the royalty fraction.
    """
    denominator: uint256 = self._fee_denominator
    assert convert(fee_numerator, uint256) <= denominator, "ERC2981: royalty fee will exceed sale_price"
    assert receiver != empty(address), "ERC2981: invalid receiver"
    self._token_royalty_info[token_id] = RoyaltyInfo({receiver: receiver, royalty_fraction: fee_numerator})


@internal
def _reset_token_royalty(token_id: uint256):
    """
    @dev Resets the royalty information for the token ID back to
         the global default.
    @notice This is an `internal` function without access restriction.
    @param token_id The 32-byte identifier of the token.
    """
    self._token_royalty_info[token_id] = RoyaltyInfo({receiver: empty(address), royalty_fraction: empty(uint96)})


@internal
def _check_owner():
    """
    @dev Sourced from {Ownable-_check_owner}.
    @notice See {Ownable-_check_owner} for
            the function docstring.
    """
    assert msg.sender == self.owner, "Ownable: caller is not the owner"


@internal
def _transfer_ownership(new_owner: address):
    """
    @dev Sourced from {Ownable-_transfer_ownership}.
    @notice See {Ownable-_transfer_ownership} for
            the function docstring.
    """
    old_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(old_owner, new_owner)
