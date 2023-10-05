# pragma version ^0.3.10
"""
@title Modern and Gas-Efficient ERC-4626 Tokenised Vault Implementation
@custom:contract-name ERC4626
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions implement the ERC-4626
        standard interface:
        - https://eips.ethereum.org/EIPS/eip-4626.
        In addition, the following functions have
        been added for convenience:
        - `permit` (`external` function),
        - `nonces` (`external` `view` function),
        - `DOMAIN_SEPARATOR` (`external` `view` function),
        - `eip712Domain` (`external` `view` function).
        The `permit` function implements approvals via
        EIP-712 secp256k1 signatures:
        https://eips.ethereum.org/EIPS/eip-2612.
        In addition, this contract also implements the EIP-5267
        function `eip712Domain`:
        https://eips.ethereum.org/EIPS/eip-5267.
        The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol,
        as well as by fubuloubu's implementation here:
        https://github.com/fubuloubu/ERC4626/blob/main/contracts/VyperVault.vy.
@custom:security Most of the following security analysis was sourced from OpenZeppelin's
                 implementation: This implementation uses virtual assets and shares to
                 mitigate the risk of inflation attacks. The `internal` `immutable` variable
                 `_DECIMALS_OFFSET` corresponds to an offset in the decimal representation
                 between the underlying asset's decimals and the vault decimals. This offset
                 also determines the rate of virtual shares to virtual assets in the vault,
                 which itself determines the initial exchange rate. While not fully
                 preventing the attack, analysis (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/docs/modules/ROOT/pages/erc4626.adoc#security-concern-inflation-attack)
                 shows that a standard offset of `0` makes it non-profitable, as a result
                 of the value being captured by the virtual shares (out of the attacker's
                 donation) matching the attacker's expected gains. With a larger offset,
                 the attack becomes orders of magnitude more expensive than it is profitable.
                 More details about the underlying mathematics can be found here:
                 https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/docs/modules/ROOT/pages/erc4626.adoc#security-concern-inflation-attack.

                 Furthermore, another potential approach would be that vault deployers can
                 protect against this attack by making an initial deposit of a non-trivial
                 amount of the asset, such that price manipulation becomes infeasible. For
                 the detailed discussion, please refer to:
                 https://ethereum-magicians.org/t/address-eip-4626-inflation-attacks-with-virtual-shares-and-assets/12677.

                 The drawback of the implemented approach is that the virtual shares do
                 capture (a very small) part of the value being accrued to the vault. Also,
                 if the vault experiences losses, the users try to exit the vault, the virtual
                 shares and assets will cause the first user to exit to experience reduced losses
                 in detriment to the last users that will experience bigger losses.
"""


# @dev We import and implement the `ERC20` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC20
implements: ERC20


# @dev We import and implement the `ERC20Detailed` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC20Detailed
implements: ERC20Detailed


# @dev We import and implement the `IERC20Permit`
# interface, which is written using standard Vyper
# syntax.
from ..tokens.interfaces.IERC20Permit import IERC20Permit
implements: IERC20Permit


# @dev We import and implement the `ERC4626` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC4626
implements: ERC4626


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ..utils.interfaces.IERC5267 import IERC5267
implements: IERC5267


# @dev Constant used as part of the ECDSA recovery function.
_MALLEABILITY_THRESHOLD: constant(bytes32) = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0


# @dev The 32-byte type hash for the EIP-712 domain separator.
_TYPE_HASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")


# @dev The 32-byte type hash of the `permit` function.
_PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")


# @dev Returns the name of the token.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable. Furthermore,
# to preserve consistency with the interface for
# the optional metadata functions of the ERC-20
# standard, we use lower case letters for the
# `immutable` variables `name`, `symbol`, and
# `decimals`.
name: public(immutable(String[25]))


# @dev Returns the symbol of the token.
# @notice See comment on lower case letters
# above at `name`.
symbol: public(immutable(String[5]))


# @dev Returns the decimals places of the token.
# @notice See comment on lower case letters
# above at `name`.
decimals: public(immutable(uint8))


# @dev Returns the address of the underlying token
# used for the vault for accounting, depositing,
# and withdrawing. To preserve consistency with the
# ERC-4626 interface, we use lower case letters for
# the `immutable` variable `name`.
# @notice Vyper returns the `address` type for interface
# types by default.
asset: public(immutable(ERC20))


# @dev Caches the domain separator as an `immutable`
# value, but also stores the corresponding chain ID
# to invalidate the cached domain separator if the
# chain ID changes.
_CACHED_DOMAIN_SEPARATOR: immutable(bytes32)
_CACHED_CHAIN_ID: immutable(uint256)


# @dev Caches `self` to `immutable` storage to avoid
# potential issues if a vanilla contract is used in
# a `delegatecall` context.
_CACHED_SELF: immutable(address)


# @dev `immutable` variables to store the (hashed)
# name and (hashed) version during contract creation.
_NAME: immutable(String[50])
_HASHED_NAME: immutable(bytes32)
_VERSION: immutable(String[20])
_HASHED_VERSION: immutable(bytes32)


# @dev An offset in the decimal representation between
# the underlying asset's decimals and the vault decimals.
# @notice While not fully preventing the attack, analysis
# (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/docs/modules/ROOT/pages/erc4626.adoc#security-concern-inflation-attack)
# shows that a standard offset of `0` makes an inflation
# attack non-profitable.
_DECIMALS_OFFSET: immutable(uint8)


# @dev Caches the underlying asset's decimals.
_UNDERLYING_DECIMALS: immutable(uint8)


# @dev Returns the amount of tokens owned by an `address`.
balanceOf: public(HashMap[address, uint256])


# @dev Returns the remaining number of tokens that a
# `spender` will be allowed to spend on behalf of
# `owner` through `transferFrom`. This is zero by
# default. This value changes when `approve` or
# `transferFrom` are called.
allowance: public(HashMap[address, HashMap[address, uint256]])


# @dev Returns the amount of tokens in existence.
totalSupply: public(uint256)


# @dev Returns the current on-chain tracked nonce
# of `address`.
nonces: public(HashMap[address, uint256])


# @dev Emitted when `amount` tokens are moved
# from one account (`owner`) to another (`to`).
# Note that the parameter `amount` may be zero.
event Transfer:
    owner: indexed(address)
    to: indexed(address)
    amount: uint256


# @dev Emitted when the allowance of a `spender`
# for an `owner` is set by a call to `approve`.
# The parameter `amount` is the new allowance.
event Approval:
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256


# @dev Emitted when `sender` has exchanged `assets`
# for `shares`, and transferred those `shares`
# to `owner`.
event Deposit:
    sender: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256


# @dev Emitted when `sender` has exchanged `shares`,
# owned by `owner`, for `assets`, and transferred
# those `assets` to `receiver`.
event Withdraw:
    sender: indexed(address)
    receiver: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256


# @dev May be emitted to signal that the domain could
# have changed.
event EIP712DomainChanged:
    pass


@external
@payable
def __init__(name_: String[25], symbol_: String[5], asset_: ERC20, decimals_offset_: uint8, name_eip712_: String[50], version_eip712_: String[20]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @param name_ The maximum 25-character user-readable
           string name of the token.
    @param symbol_ The maximum 5-character user-readable
           string symbol of the token.
    @param asset_ The ERC-20 compatible (i.e. ERC-777 is also viable)
           underlying asset contract.
    @param decimals_offset_ The 1-byte offset in the decimal
           representation between the underlying asset's
           decimals and the vault decimals. The recommended value to
           mitigate the risk of an inflation attack is `0`.
    @param name_eip712_ The maximum 50-character user-readable
           string name of the signing domain, i.e. the name
           of the dApp or protocol.
    @param version_eip712_ The maximum 20-character current
           main version of the signing domain. Signatures
           from different versions are not compatible.
    """
    name = name_
    symbol = symbol_
    asset = asset_

    success: bool = empty(bool)
    decoded_decimals: uint8 = empty(uint8)
    # Attempt to fetch the underlying's decimals. A return
    # value of `False` indicates that the attempt failed in
    # some way.
    success, decoded_decimals = self._try_get_underlying_decimals(asset_)

    _UNDERLYING_DECIMALS = decoded_decimals if success else 18
    _DECIMALS_OFFSET = decimals_offset_
    # The following line uses intentionally checked arithmetic
    # to prevent a theoretically possible overflow.
    decimals = _UNDERLYING_DECIMALS + _DECIMALS_OFFSET

    _NAME = name_eip712_
    _VERSION = version_eip712_
    _HASHED_NAME = keccak256(name_eip712_)
    _HASHED_VERSION = keccak256(version_eip712_)
    _CACHED_DOMAIN_SEPARATOR = self._build_domain_separator()
    _CACHED_CHAIN_ID = chain.id
    _CACHED_SELF = self


@external
def transfer(to: address, amount: uint256) -> bool:
    """
    @dev Sourced from {ERC20-transfer}.
    @notice See {ERC20-transfer} for the function
            docstring.
    """
    self._transfer(msg.sender, to, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    """
    @dev Sourced from {ERC20-approve}.
    @notice See {ERC20-approve} for the function
            docstring.
    """
    self._approve(msg.sender, spender, amount)
    return True


@external
def transferFrom(owner: address, to: address, amount: uint256) -> bool:
    """
    @dev Sourced from {ERC20-transferFrom}.
    @notice See {ERC20-transferFrom} for the function
            docstring.
    """
    self._spend_allowance(owner, msg.sender, amount)
    self._transfer(owner, to, amount)
    return True


@external
def permit(owner: address, spender: address, amount: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32):
    """
    @dev Sourced from {ERC20-permit}.
    @notice See {ERC20-permit} for the function
            docstring.
    """
    assert block.timestamp <= deadline, "ERC20Permit: expired deadline"

    current_nonce: uint256 = self.nonces[owner]
    self.nonces[owner] = unsafe_add(current_nonce, 1)

    struct_hash: bytes32 = keccak256(_abi_encode(_PERMIT_TYPE_HASH, owner, spender, amount, current_nonce, deadline))
    hash: bytes32  = self._hash_typed_data_v4(struct_hash)

    signer: address = self._recover_vrs(hash, convert(v, uint256), convert(r, uint256), convert(s, uint256))
    assert signer == owner, "ERC20Permit: invalid signature"

    self._approve(owner, spender, amount)


@external
@view
def DOMAIN_SEPARATOR() -> bytes32:
    """
    @dev Sourced from {ERC20-DOMAIN_SEPARATOR}.
    @notice See {ERC20-DOMAIN_SEPARATOR} for the
            function docstring.
    """
    return self._domain_separator_v4()


@external
@view
def eip712Domain() -> (bytes1, String[50], String[20], uint256, address, bytes32, DynArray[uint256, 128]):
    """
    @dev Returns the fields and values that describe the domain
         separator used by this contract for EIP-712 signatures.
    @notice The bits in the 1-byte bit map are read from the least
            significant to the most significant, and fields are indexed
            in the order that is specified by EIP-712, identical to the
            order in which they are listed in the function type.
    @return bytes1 The 1-byte bit map where bit `i` is set to 1
            if and only if domain field `i` is present (`0 ≤ i ≤ 4`).
    @return String The maximum 50-character user-readable string name
            of the signing domain, i.e. the name of the dApp or protocol.
    @return String The maximum 20-character current main version of
            the signing domain. Signatures from different versions are
            not compatible.
    @return uint256 The 32-byte EIP-155 chain ID.
    @return address The 20-byte address of the verifying contract.
    @return bytes32 The 32-byte disambiguation salt for the protocol.
    @return DynArray The 32-byte array of EIP-712 extensions.
    """
    # Note that `\x0f` equals `01111`.
    return (convert(b"\x0f", bytes1), _NAME, _VERSION, chain.id, self, empty(bytes32), empty(DynArray[uint256, 128]))


@external
@view
def totalAssets() -> uint256:
    """
    @dev Returns the total amount of the underlying asset
         that is managed by the vault.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#totalassets.
    @return uint256 The 32-byte total managed assets.
    """
    return self._total_assets()


@external
@view
def convertToShares(assets: uint256) -> uint256:
    """
    @dev Returns the amount of shares that the vault would
         exchange for the amount of assets provided, in an
         ideal scenario where all the conditions are met.
    @notice Note that the conversion must round down to 0.
            For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#converttoshares.
    @param assets The 32-byte assets amount.
    @return uint256 The converted 32-byte shares amount.
    """
    return self._convert_to_shares(assets, False)


@external
@view
def convertToAssets(shares: uint256) -> uint256:
    """
    @dev Returns the amount of assets that the vault would
         exchange for the amount of shares provided, in an
         ideal scenario where all the conditions are met.
    @notice Note that the conversion must round down to 0.
            For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#converttoassets.
    @param shares The 32-byte shares amount.
    @return uint256 The converted 32-byte assets amount.
    """
    return self._convert_to_assets(shares, False)


@external
@view
def maxDeposit(receiver: address) -> uint256:
    """
    @dev Returns the maximum amount of the underlying asset
         that can be deposited into the vault for the `receiver`,
         through a `deposit` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxdeposit.
    @param receiver The 20-byte receiver address.
    @return uint256 The 32-byte maximum deposit amount.
    """
    return self._max_deposit(receiver)


@external
@view
def previewDeposit(assets: uint256) -> uint256:
    """
    @dev Allows an on-chain or off-chain user to simulate the
         effects of their deposit at the current block, given
         current on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewdeposit.
    @param assets The 32-byte assets amount.
    @return uint256 The simulated 32-byte returning shares amount.
    """
    return self._preview_deposit(assets)


@external
def deposit(assets: uint256, receiver: address) -> uint256:
    """
    @dev Mints `shares` vault shares to `receiver` by depositing
         exactly `assets` of underlying tokens.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#deposit.
    @param assets The 32-byte assets amount.
    @param receiver The 20-byte receiver address.
    @return uint256 The 32-byte shares amount to be created.
    """
    assert assets <= self._max_deposit(receiver), "ERC4626: deposit more than maximum"
    shares: uint256 = self._preview_deposit(assets)
    self._deposit(msg.sender, receiver, assets, shares)
    return shares


@external
@view
def maxMint(receiver: address) -> uint256:
    """
    @dev Returns the maximum amount of shares that can be minted
         from the vault for the `receiver`, through a `mint` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxmint.
    @param receiver The 20-byte receiver address.
    @return uint256 The 32-byte maximum mint amount.
    """
    return self._max_mint(receiver)


@external
@view
def previewMint(shares: uint256) -> uint256:
    """
    @dev Allows an on-chain or off-chain user to simulate the
         effects of their `mint` at the current block, given
         current on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewmint.
    @param shares The 32-byte shares amount.
    @return uint256 The simulated 32-byte required assets amount.
    """
    return self._preview_mint(shares)


@external
def mint(shares: uint256, receiver:address) -> uint256:
    """
    @dev Mints exactly `shares` vault shares to `receiver` by
         depositing `assets` of underlying tokens.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#mint.
    @param shares The 32-byte shares amount to be created.
    @param receiver The 20-byte receiver address.
    @return uint256 The deposited 32-byte assets amount.
    """
    assert shares <= self._max_mint(receiver), "ERC4626: mint more than maximum"
    assets: uint256 = self._preview_mint(shares)
    self._deposit(msg.sender, receiver, assets, shares)
    return assets


@external
@view
def maxWithdraw(owner: address) -> uint256:
    """
    @dev Returns the maximum amount of the underlying asset that
         can be withdrawn from the owner balance in the vault,
         through a `withdraw` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxwithdraw.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte maximum withdraw amount.
    """
    return self._max_withdraw(owner)


@external
@view
def previewWithdraw(assets: uint256) -> uint256:
    """
    @dev Allows an on-chain or off-chain user to simulate the
         effects of their withdrawal at the current block, given
         current on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewwithdraw.
    @param assets The 32-byte assets amount.
    @return uint256 The simulated 32-byte burned shares amount.
    """
    return self._preview_withdraw(assets)


@external
def withdraw(assets: uint256, receiver: address, owner: address) -> uint256:
    """
    @dev Burns `shares` from `owner` and sends exactly `assets` of
         underlying tokens to `receiver`.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#withdraw.
    @param assets The 32-byte assets amount to be withdrawn.
    @param receiver The 20-byte receiver address.
    @param owner The 20-byte owner address.
    @return uint256 The burned 32-byte shares amount.
    """
    assert assets <= self._max_withdraw(receiver), "ERC4626: withdraw more than maximum"
    shares: uint256 = self._preview_withdraw(assets)
    self._withdraw(msg.sender, receiver, owner, assets, shares)
    return shares


@external
@view
def maxRedeem(owner: address) -> uint256:
    """
    @dev Maximum amount of vault shares that can be redeemed from
         the `owner` balance in the vault, through a `redeem` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxredeem.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte maximum redeemable shares amount.
    """
    return self._max_redeem(owner)


@external
@view
def previewRedeem(shares: uint256) -> uint256:
    """
    @dev Allows an on-chain or off-chain user to simulate the effects
         of their redeemption at the current block, given current
         on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewredeem.
    @param shares The 32-byte shares amount to be redeemed.
    @return uint256 The simulated 32-byte returning assets amount.
    """
    return self._preview_redeem(shares)


@external
def redeem(shares: uint256, receiver: address, owner: address) -> uint256:
    """
    @dev Burns exactly `shares` from `owner` and sends `assets` of
         underlying tokens to `receiver`.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#redeem.
    @param shares The 32-byte redeemed shares amount.
    @param receiver The 20-byte receiver address.
    @param owner The 20-byte owner address.
    @return uint256 The returned 32-byte assets amount.
    """
    assert shares <= self._max_redeem(owner), "ERC4626: redeem more than maximum"
    assets: uint256 = self._preview_redeem(shares)
    self._withdraw(msg.sender, receiver, owner, assets, shares)
    return assets


@internal
def _transfer(owner: address, to: address, amount: uint256):
    """
    @dev Sourced from {ERC20-_transfer}.
    @notice See {ERC20-_transfer} for the function
            docstring.
    """
    assert owner != empty(address), "ERC20: transfer from the zero address"
    assert to != empty(address), "ERC20: transfer to the zero address"

    self._before_token_transfer(owner, to, amount)

    owner_balanceOf: uint256 = self.balanceOf[owner]
    assert owner_balanceOf >= amount, "ERC20: transfer amount exceeds balance"
    self.balanceOf[owner] = unsafe_sub(owner_balanceOf, amount)
    self.balanceOf[to] = unsafe_add(self.balanceOf[to], amount)
    log Transfer(owner, to, amount)

    self._after_token_transfer(owner, to, amount)


@internal
def _mint(owner: address, amount: uint256):
    """
    @dev Sourced from {ERC20-_mint}.
    @notice See {ERC20-_mint} for the function
            docstring.
    """
    assert owner != empty(address), "ERC20: mint to the zero address"

    self._before_token_transfer(empty(address), owner, amount)

    self.totalSupply += amount
    self.balanceOf[owner] = unsafe_add(self.balanceOf[owner], amount)
    log Transfer(empty(address), owner, amount)

    self._after_token_transfer(empty(address), owner, amount)


@internal
def _burn(owner: address, amount: uint256):
    """
    @dev Sourced from {ERC20-_burn}.
    @notice See {ERC20-_burn} for the function
            docstring.
    """
    assert owner != empty(address), "ERC20: burn from the zero address"

    self._before_token_transfer(owner, empty(address), amount)

    account_balance: uint256 = self.balanceOf[owner]
    assert account_balance >= amount, "ERC20: burn amount exceeds balance"
    self.balanceOf[owner] = unsafe_sub(account_balance, amount)
    self.totalSupply = unsafe_sub(self.totalSupply, amount)
    log Transfer(owner, empty(address), amount)

    self._after_token_transfer(owner, empty(address), amount)


@internal
def _approve(owner: address, spender: address, amount: uint256):
    """
    @dev Sourced from {ERC20-_approve}.
    @notice See {ERC20-_approve} for the function
            docstring.
    """
    assert owner != empty(address), "ERC20: approve from the zero address"
    assert spender != empty(address), "ERC20: approve to the zero address"

    self.allowance[owner][spender] = amount
    log Approval(owner, spender, amount)


@internal
def _spend_allowance(owner: address, spender: address, amount: uint256):
    """
    @dev Sourced from {ERC20-_approve}.
    @notice See {ERC20-_spend_allowance} for the
            function docstring.
    """
    current_allowance: uint256 = self.allowance[owner][spender]
    if (current_allowance != max_value(uint256)):
        # The following line allows the commonly known address
        # poisoning attack, where `transferFrom` instructions
        # are executed from arbitrary addresses with an `amount`
        # of 0. However, this poisoning attack is not an on-chain
        # vulnerability. All assets are safe. It is an off-chain
        # log interpretation issue.
        assert current_allowance >= amount, "ERC20: insufficient allowance"
        self._approve(owner, spender, unsafe_sub(current_allowance, amount))


@internal
def _before_token_transfer(owner: address, to: address, amount: uint256):
    """
    @dev Sourced from {ERC20-_before_token_transfer}.
    @notice See {ERC20-_before_token_transfer} for
            the function docstring.
    """
    pass


@internal
def _after_token_transfer(owner: address, to: address, amount: uint256):
    """
    @dev Sourced from {ERC20-_after_token_transfer}.
    @notice See {ERC20-_after_token_transfer} for
            the function docstring.
    """
    pass


@internal
@view
def _domain_separator_v4() -> bytes32:
    """
    @dev Sourced from {EIP712DomainSeparator-domain_separator_v4}.
    @notice See {EIP712DomainSeparator-domain_separator_v4}
            for the function docstring.
    """
    if (self == _CACHED_SELF and chain.id == _CACHED_CHAIN_ID):
        return _CACHED_DOMAIN_SEPARATOR
    else:
        return self._build_domain_separator()


@internal
@view
def _build_domain_separator() -> bytes32:
    """
    @dev Sourced from {EIP712DomainSeparator-_build_domain_separator}.
    @notice See {EIP712DomainSeparator-_build_domain_separator}
            for the function docstring.
    """
    return keccak256(_abi_encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, chain.id, self))


@internal
@view
def _hash_typed_data_v4(struct_hash: bytes32) -> bytes32:
    """
    @dev Sourced from {EIP712DomainSeparator-hash_typed_data_v4}.
    @notice See {EIP712DomainSeparator-hash_typed_data_v4}
            for the function docstring.
    """
    return self._to_typed_data_hash(self._domain_separator_v4(), struct_hash)


@internal
@pure
def _to_typed_data_hash(domain_separator: bytes32, struct_hash: bytes32) -> bytes32:
    """
    @dev Sourced from {ECDSA-to_typed_data_hash}.
    @notice See {ECDSA-to_typed_data_hash} for the
            function docstring.
    """
    return keccak256(concat(b"\x19\x01", domain_separator, struct_hash))


@internal
@pure
def _recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Sourced from {ECDSA-_recover_vrs}.
    @notice See {ECDSA-_recover_vrs} for the
            function docstring.
    """
    return self._try_recover_vrs(hash, v, r, s)


@internal
@pure
def _try_recover_vrs(hash: bytes32, v: uint256, r: uint256, s: uint256) -> address:
    """
    @dev Sourced from {ECDSA-_try_recover_vrs}.
    @notice See {ECDSA-_try_recover_vrs} for the
            function docstring.
    """
    assert s <= convert(_MALLEABILITY_THRESHOLD, uint256), "ECDSA: invalid signature `s` value"

    signer: address = ecrecover(hash, v, r, s)
    assert signer != empty(address), "ECDSA: invalid signature"

    return signer


@internal
@view
def _try_get_underlying_decimals(underlying: ERC20) -> (bool, uint8):
    """
    @dev Attempts to fetch the underlying's decimals. A return
         value of `False` indicates that the attempt failed in
         some way.
    @param underlying The ERC-20 compatible (i.e. ERC-777 is also viable)
           underlying asset contract.
    @return bool The verification whether the call succeeded or
            failed.
    @return uint8 The fetched underlying's decimals.
    """
    success: bool = empty(bool)
    return_data: Bytes[32] = b""
    # The following low-level call does not revert, but instead
    # returns `False` if the callable contract does not implement
    # the `decimals` function. Since we perform a length check of
    # 32 bytes for the return data in the return expression at the
    # end, we also return `False` for EOA wallets instead of reverting
    # (remember that the EVM always considers a call to an EOA as
    # successful with return data `0x`). Furthermore, it is important
    # to note that an external call via `raw_call` does not perform an
    # external code size check on the target address.
    success, return_data = raw_call(underlying.address, method_id("decimals()"), max_outsize=32, is_static_call=True, revert_on_failure=False)
    if (success and (len(return_data) == 32) and (convert(return_data, uint256) <= convert(max_value(uint8), uint256))):
        return (True, convert(return_data, uint8))
    return (False, empty(uint8))


@internal
@view
def _total_assets() -> uint256:
    """
    @dev An `internal` helper function that returns the total amount
         of the underlying asset that is managed by the vault.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#totalassets.
    @return uint256 The 32-byte total managed assets.
    """
    return asset.balanceOf(self)


@internal
@view
def _convert_to_shares(assets: uint256, roundup: bool) -> uint256:
    """
    @dev An `internal` conversion function (from assets to shares)
         with support for rounding direction.
    @param assets The 32-byte assets amount.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The converted 32-byte shares amount.
    """
    return self._mul_div(assets, self.totalSupply + 10 ** convert(_DECIMALS_OFFSET, uint256), self._total_assets() + 1, roundup)


@internal
@view
def _convert_to_assets(shares: uint256, roundup: bool) -> uint256:
    """
    @dev An `internal` conversion function (from shares to assets)
         with support for rounding direction.
    @param shares The 32-byte shares amount.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The converted 32-byte assets amount.
    """
    return self._mul_div(shares, self._total_assets() + 1, self.totalSupply + 10 ** convert(_DECIMALS_OFFSET, uint256), roundup)


@internal
@pure
def _max_deposit(receiver: address) -> uint256:
    """
    @dev An `internal` helper function that returns the maximum
         amount of the underlying asset that can be deposited into
         the vault for the `receiver`, through a `deposit` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxdeposit.
    @param receiver The 20-byte receiver address.
    @return uint256 The 32-byte maximum deposit amount.
    """
    return max_value(uint256)


@internal
@view
def _preview_deposit(assets: uint256) -> uint256:
    """
    @dev An `internal` helper function that allows an on-chain or
         off-chain user to simulate the effects of their deposit at
         the current block, given current on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewdeposit.
    @param assets The 32-byte assets amount.
    @return uint256 The simulated 32-byte returning shares amount.
    """
    return self._convert_to_shares(assets, False)


@internal
@pure
def _max_mint(receiver: address) -> uint256:
    """
    @dev An `internal` helper function that returns the maximum
         amount of shares that can be minted from the vault for
         the `receiver`, through a `mint` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxmint.
    @param receiver The 20-byte receiver address.
    @return uint256 The 32-byte maximum mint amount.
    """
    return max_value(uint256)


@internal
@view
def _preview_mint(shares: uint256) -> uint256:
    """
    @dev An `internal` helper function that allows an on-chain or
         off-chain user to simulate the effects of their `mint` at
         the current block, given current on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewmint.
    @param shares The 32-byte shares amount.
    @return uint256 The simulated 32-byte required assets amount.
    """
    return self._convert_to_assets(shares, True)


@internal
@view
def _max_withdraw(owner: address) -> uint256:
    """
    @dev An `internal` helper function that returns the maximum
         amount of the underlying asset that can be withdrawn from
         the owner balance in the vault, through a `withdraw` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxwithdraw.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte maximum withdraw amount.
    """
    return self._convert_to_assets(self.balanceOf[owner], False)


@internal
@view
def _preview_withdraw(assets: uint256) -> uint256:
    """
    @dev An `internal` helper function that allows an on-chain or
         off-chain user to simulate the effects of their withdrawal
         at the current block, given current on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewwithdraw.
    @param assets The 32-byte assets amount.
    @return uint256 The simulated 32-byte burned shares amount.
    """
    return self._convert_to_shares(assets, True)


@internal
@view
def _max_redeem(owner: address) -> uint256:
    """
    @dev An `internal` helper function that returns the maximum
         amount of vault shares that can be redeemed from the `owner`
         balance in the vault, through a `redeem` call.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#maxredeem.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte maximum redeemable shares amount.
    """
    return self.balanceOf[owner]


@internal
@view
def _preview_redeem(shares: uint256) -> uint256:
    """
    @dev An `internal` helper function that allows an on-chain or
         off-chain user to simulate the effects of their redeemption
         at the current block, given current on-chain conditions.
    @notice For the to be fulfilled conditions, please refer to:
            https://eips.ethereum.org/EIPS/eip-4626#previewredeem.
    @param shares The 32-byte shares amount to be redeemed.
    @return uint256 The simulated 32-byte returning assets amount.
    """
    return self._convert_to_assets(shares, False)


@internal
def _deposit(sender: address, receiver: address, assets: uint256, shares: uint256):
    """
    @dev An `internal` function handling the `deposit` and `mint`
         common workflow.
    @param sender The 20-byte sender address.
    @param receiver The 20-byte receiver address.
    @param assets The 32-byte assets amount.
    @param shares The 32-byte shares amount.
    """
    # If `asset` is an ERC-777, `transferFrom` can trigger a reentrancy
    # before the transfer happens through the `tokensToSend` hook. On the
    # other hand, the `tokenReceived` hook, that is triggered after the
    # transfer, calls the vault which is assumed not to be malicious.
    # Thus, we need to do the transfer before we mint so that any reentrancy
    # would happen before the assets are transferred and before the shares
    # are minted, which is a valid state.

    # To deal with (potentially) non-compliant ERC-20 tokens that do have
    # no return value, we use the kwarg `default_return_value` for external
    # calls. This function was introduced in Vyper version 0.3.4. For more
    # details see:
    # - https://github.com/vyperlang/vyper/pull/2839,
    # - https://github.com/vyperlang/vyper/issues/2812,
    # - https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca.

    # It is important to note that an external call via interface casting
    # always performs an external code size check on the target address unless
    # you add the kwarg `skip_contract_check=True`. If the check fails (i.e.
    # the target address is an EOA), the call reverts.
    assert asset.transferFrom(sender, self, assets, default_return_value=True), "ERC4626: transferFrom operation did not succeed"
    self._mint(receiver, shares)
    log Deposit(sender, receiver, assets, shares)


@internal
def _withdraw(sender: address, receiver: address, owner: address, assets: uint256, shares: uint256):
    """
    @dev An `internal` function handling the `withdraw` and `redeem`
         common workflow.
    @param sender The 20-byte sender address.
    @param receiver The 20-byte receiver address.
    @param owner The 20-byte owner address.
    @param assets The 32-byte assets amount.
    @param shares The 32-byte shares amount.
    """
    if (sender != owner):
        self._spend_allowance(owner, sender, shares)

    # If `asset` is an ERC-777, `transfer` can trigger a reentrancy
    # after the transfer happens through the `tokensReceived` hook.
    # On the other hand, the `tokensToSend` hook, that is triggered
    # before the transfer, calls the vault which is assumed not to
    # be malicious. Thus, we need to do the transfer after the burn
    # so that any reentrancy would happen after the shares are burned
    # and after the assets are transferred, which is a valid state.
    self._burn(owner, shares)

    # To deal with (potentially) non-compliant ERC-20 tokens that do have
    # no return value, we use the kwarg `default_return_value` for external
    # calls. This function was introduced in Vyper version 0.3.4. For more
    # details see:
    # - https://github.com/vyperlang/vyper/pull/2839,
    # - https://github.com/vyperlang/vyper/issues/2812,
    # - https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca.

    # It is important to note that an external call via interface casting
    # always performs an external code size check on the target address unless
    # you add the kwarg `skip_contract_check=True`. If the check fails (i.e.
    # the target address is an EOA), the call reverts.
    assert asset.transfer(receiver, assets, default_return_value=True), "ERC4626: transfer operation did not succeed"
    log Withdraw(sender, receiver, owner, assets, shares)


@internal
@pure
def _mul_div(x: uint256, y: uint256, denominator: uint256, roundup: bool) -> uint256:
    """
    @dev Sourced from {Math-mul_div}.
    @notice See {Math-mul_div} for the function
            docstring.
    """
    # Handle division by zero.
    assert denominator != empty(uint256), "Math: mul_div division by zero"

    # 512-bit multiplication "[prod1 prod0] = x * y".
    # Compute the product "mod 2**256" and "mod 2**256 - 1".
    # Then use the Chinese Remainder theorem to reconstruct
    # the 512-bit result. The result is stored in two 256-bit
    # variables, where: "product = prod1 * 2**256 + prod0".
    mm: uint256 = uint256_mulmod(x, y, max_value(uint256))
    # The least significant 256 bits of the product.
    prod0: uint256 = unsafe_mul(x, y)
    # The most significant 256 bits of the product.
    prod1: uint256 = empty(uint256)

    if (mm < prod0):
        prod1 = unsafe_sub(unsafe_sub(mm, prod0), 1)
    else:
        prod1 = unsafe_sub(mm, prod0)

    # Handling of non-overflow cases, 256 by 256 division.
    if (prod1 == empty(uint256)):
        if (roundup and uint256_mulmod(x, y, denominator) != empty(uint256)):
            # Calculate "ceil((x * y) / denominator)". The following
            # line cannot overflow because we have the previous check
            # "(x * y) % denominator != 0", which accordingly rules out
            # the possibility of "x * y = 2**256 - 1" and `denominator == 1`.
            return unsafe_add(unsafe_div(prod0, denominator), 1)
        else:
            return unsafe_div(prod0, denominator)

    # Ensure that the result is less than 2**256. Also,
    # prevents that `denominator == 0`.
    assert denominator > prod1, "Math: mul_div overflow"

    #######################
    # 512 by 256 Division #
    #######################

    # Make division exact by subtracting the remainder
    # from "[prod1 prod0]". First, compute remainder using
    # the `uint256_mulmod` operation.
    remainder: uint256 = uint256_mulmod(x, y, denominator)

    # Second, subtract the 256-bit number from the 512-bit
    # number.
    if (remainder > prod0):
        prod1 = unsafe_sub(prod1, 1)
    prod0 = unsafe_sub(prod0, remainder)

    # Factor powers of two out of the denominator and calculate
    # the largest power of two divisor of denominator. Always `>= 1`,
    # unless the denominator is zero (which is prevented above),
    # in which case `twos` is zero. For more details, please refer to:
    # https://cs.stackexchange.com/q/138556.
    twos: uint256 = unsafe_sub(0, denominator) & denominator
    # Divide denominator by `twos`.
    denominator_div: uint256 = unsafe_div(denominator, twos)
    # Divide "[prod1 prod0]" by `twos`.
    prod0 = unsafe_div(prod0, twos)
    # Flip `twos` such that it is "2**256 / twos". If `twos` is zero,
    # it becomes one.
    twos = unsafe_add(unsafe_div(unsafe_sub(empty(uint256), twos), twos), 1)

    # Shift bits from `prod1` to `prod0`.
    prod0 |= unsafe_mul(prod1, twos)

    # Invert the denominator "mod 2**256". Since the denominator is
    # now an odd number, it has an inverse modulo 2**256, so we have:
    # "denominator * inverse = 1 mod 2**256". Calculate the inverse by
    # starting with a seed that is correct for four bits. That is,
    # "denominator * inverse = 1 mod 2**4".
    inverse: uint256 = unsafe_mul(3, denominator_div) ^ 2

    # Use Newton-Raphson iteration to improve accuracy. Thanks to Hensel's
    # lifting lemma, this also works in modular arithmetic by doubling the
    # correct bits in each step.
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**8".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**16".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**32".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**64".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**128".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**256".

    # Since the division is now exact, we can divide by multiplying
    # with the modular inverse of the denominator. This returns the
    # correct result modulo 2**256. Since the preconditions guarantee
    # that the result is less than 2**256, this is the final result.
    # We do not need to calculate the high bits of the result and
    # `prod1` is no longer necessary.
    result: uint256 = unsafe_mul(prod0, inverse)

    if (roundup and uint256_mulmod(x, y, denominator) != empty(uint256)):
        # Calculate "ceil((x * y) / denominator)". The following
        # line uses intentionally checked arithmetic to prevent
        # a theoretically possible overflow.
        result += 1

    return result
