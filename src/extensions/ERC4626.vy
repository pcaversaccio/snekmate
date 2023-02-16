# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-4626 Tokenised Vault Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


# @dev We import and implement the `ERC20` interface,
# which is a built-in interface of the Vyper compiler.
# @notice We do not import the interface `ERC20Detailed`
# (https://github.com/vyperlang/vyper/blob/master/vyper/builtin_interfaces/ERC20Detailed.py)
# to be able to declare `name`, `symbol`, and `decimals`
# as `immutable` variables. This is a known compiler bug
# (https://github.com/vyperlang/vyper/issues/3130) and
# we will import the interface `ERC20Detailed` once it
# is fixed.
from vyper.interfaces import ERC20
implements: ERC20


# @dev We import and implement the `IERC20Permit`
# interface, which is written using standard Vyper
# syntax.
import src.tokens.interfaces.IERC20Permit as IERC20Permit
implements: IERC20Permit


# @dev We import and implement the `ERC4626` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC4626
#implements: ERC4626


# @dev Constant used as part of the ECDSA recovery function.
_MALLEABILITY_THRESHOLD: constant(bytes32) = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0


# @dev The 32-byte type hash of the `permit` function.
_PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")


# @dev Returns the name of the token.
# @notice See comment on lower case letters
# above at `decimals`.
name: public(immutable(String[25]))


# @dev Returns the symbol of the token.
# @notice See comment on lower case letters
# above at `decimals`.
symbol: public(immutable(String[5]))


# @dev TBD
decimals: public(immutable(uint8))


# @dev Vyper will automatically return the `address` type here.
asset: public(immutable(ERC20))


# @dev TBD
_DECIMALS_OFFSET: immutable(uint8)


# @dev TBD
_UNDERLYING_DECIMALS: immutable(uint8)


# @dev Caches the domain separator as an `immutable`
# value, but also store the corresponding chain id
# to invalidate the cached domain separator if the
# chain id changes.
_CACHED_CHAIN_ID: immutable(uint256)
_CACHED_SELF: immutable(address)
_CACHED_DOMAIN_SEPARATOR: immutable(bytes32)


# @dev `immutable` variables to store the name,
# version, and type hash during contract creation.
_HASHED_NAME: immutable(bytes32)
_HASHED_VERSION: immutable(bytes32)
_TYPE_HASH: immutable(bytes32)


# @dev Returns the amount of tokens owned by an `address`.
balanceOf: public(HashMap[address, uint256])


# @dev Returns the remaining number of tokens that a
# `spender` will be allowed to spend on behalf of
# `owner` through `transferFrom`. This is zero by
# default. This value changes when `approve`,
# `increase_allowance`, `decrease_allowance`, or
# `transferFrom` are called.
allowance: public(HashMap[address, HashMap[address, uint256]])


# @dev Returns the amount of tokens in existence.
totalSupply: public(uint256)


# @dev Returns the current on-chain tracked nonce
# of `address`.
nonces: public(HashMap[address, uint256])


# @dev TBD
enum Rounding:
    DOWN
    UP


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
    @param asset_ TBD.
    @param decimals_offset_ TBD
    @param name_eip712_ The maximum 50-character user-readable
           string name of the signing domain, i.e. the name
           of the dApp or protocol.
    @param version_eip712_ The maximum 20-character current
           main version of the signing domain. Signatures
           from different versions are not compatible.
    """
    name = name_
    symbol = symbol_

    success: bool = empty(bool)
    underlying_decimals: uint8 = empty(uint8)
    asset_decimals: uint8 = empty(uint8)
    success, decimals = self._try_get_underlying_decimals(asset_)

    # issue: https://github.com/vyperlang/vyper/issues/3278
    if (success):
        underlying_decimals = decimals
    else:
        underlying_decimals = 18

    _UNDERLYING_DECIMALS = underlying_decimals
    _DECIMALS_OFFSET = decimals_offset_
    decimals = _UNDERLYING_DECIMALS + _DECIMALS_OFFSET
    asset = asset_

    hashed_name: bytes32 = keccak256(convert(name_eip712_, Bytes[50]))
    hashed_version: bytes32 = keccak256(convert(version_eip712_, Bytes[20]))
    type_hash: bytes32 = keccak256(convert("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)", Bytes[82]))
    _HASHED_NAME = hashed_name
    _HASHED_VERSION = hashed_version
    _TYPE_HASH = type_hash
    _CACHED_CHAIN_ID = chain.id
    _CACHED_SELF = self
    _CACHED_DOMAIN_SEPARATOR = self._build_domain_separator(type_hash, hashed_name, hashed_version)


@external
def transfer(to: address, amount: uint256) -> bool:
    """
    @dev Moves `amount` tokens from the caller's
         account to `to`.
    @notice Note that `to` cannot be the zero address.
            Also, the caller must have a balance of at
            least `amount`.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount to be transferred.
    @return bool The verification whether the transfer succeeded
            or failed. Note that the function reverts instead
            of returning `False` on a failure.
    """
    self._transfer(msg.sender, to, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    """
    @dev Sets `amount` as the allowance of `spender`
         over the caller's tokens.
    @notice WARNING: Note that if `amount` is the maximum
            `uint256`, the allowance is not updated on
            `transferFrom`. This is semantically equivalent
            to an infinite approval. Also, `spender` cannot
            be the zero address.

            IMPORTANT: Beware that changing an allowance
            with this method brings the risk that someone
            may use both the old and the new allowance by
            unfortunate transaction ordering. One possible
            solution to mitigate this race condition is to
            first reduce the spender's allowance to 0 and
            set the desired amount afterwards:
            https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
    @param spender The 20-byte spender address.
    @param amount The 32-byte token amount that is
           allowed to be spent by the `spender`.
    @return bool The verification whether the approval operation
            succeeded or failed. Note that the function reverts
            instead of returning `False` on a failure.
    """
    self._approve(msg.sender, spender, amount)
    return True


@external
def transferFrom(owner: address, to: address, amount: uint256) -> bool:
    """
    @dev Moves `amount` tokens from `owner`
         to `to` using the allowance mechanism.
         The `amount` is then deducted from the
         caller's allowance.
    @notice Note that `owner` and `to` cannot
            be the zero address. Also, `owner`
            must have a balance of at least `amount`.
            Eventually, the caller must have allowance
            for `owner`'s tokens of at least `amount`.

            WARNING: The function does not update the
            allowance if the current allowance is the
            maximum `uint256`.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount to be transferred.
    @return bool The verification whether the transfer succeeded
            or failed. Note that the function reverts instead
            of returning `False` on a failure.
    """
    self._spend_allowance(owner, msg.sender, amount)
    self._transfer(owner, to, amount)
    return True


@external
def increase_allowance(spender: address, added_amount: uint256) -> bool:
    """
    @dev Atomically increases the allowance granted to
         `spender` by the caller.
    @notice This is an alternative to `approve` that can
            be used as a mitigation for the problems
            described in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
            Note that `spender` cannot be the zero address.
    @param spender The 20-byte spender address.
    @param added_amount The 32-byte token amount that is
           added atomically to the allowance of the `spender`.
    @return bool The verification whether the allowance increase
            operation succeeded or failed. Note that the function
            reverts instead of returning `False` on a failure.
    """
    self._approve(msg.sender, spender, self.allowance[msg.sender][spender] + added_amount)
    return True


@external
def decrease_allowance(spender: address, subtracted_amount: uint256) -> bool:
    """
    @dev Atomically decreases the allowance granted to
         `spender` by the caller.
    @notice This is an alternative to `approve` that can
            be used as a mitigation for the problems
            described in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
            Note that `spender` cannot be the zero address.
            Also, `spender` must have an allowance for
            the caller of at least `subtracted_amount`.
    @param spender The 20-byte spender address.
    @param subtracted_amount The 32-byte token amount that is
           subtracted atomically from the allowance of the `spender`.
    @return bool The verification whether the allowance decrease
            operation succeeded or failed. Note that the function
            reverts instead of returning `False` on a failure.
    """
    current_allowance: uint256 = self.allowance[msg.sender][spender]
    assert current_allowance >= subtracted_amount, "ERC20: decreased allowance below zero"
    self._approve(msg.sender, spender, unsafe_sub(current_allowance, subtracted_amount))
    return True


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
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    return self._domain_separator_v4()


@external
@view
def totalAssets() -> uint256:
    return asset.balanceOf(self)


@external
@view
def convertToShares(assets: uint256) -> uint256:
    return self._convert_to_shares(assets, Rounding.DOWN)


@internal
@view
def _try_get_underlying_decimals(underlying: ERC20) -> (bool, uint8):
    """
    @dev TBD
    @notice TBD
    @param underlying TBD
    @return bool TBD
    @return uint8 TBD
    """
    success: bool = empty(bool)
    return_data: Bytes[32] = b""
    success, return_data = raw_call(underlying.address, method_id("decimals()"), max_outsize=32, is_static_call=True, revert_on_failure=False)
    if (success and (len(return_data) == 32) and (convert(return_data, uint256) <= convert(max_value(uint8), uint256))):
        return (True, convert(return_data, uint8))
    return (success, empty(uint8))


@internal
def _transfer(owner: address, to: address, amount: uint256):
    """
    @dev Moves `amount` tokens from the owner's
         account to `to`.
    @notice Note that `owner` and `to` cannot be
            the zero address. Also, `owner` must
            have a balance of at least `amount`.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount to be transferred.
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
    @dev Creates `amount` tokens and assigns
         them to `owner`, increasing the
         total supply.
    @notice This is an `internal` function without
            access restriction. Note that `owner`
            cannot be the zero address.
    @param owner The 20-byte owner address.
    @param amount The 32-byte token amount to be created.
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
    @dev Destroys `amount` tokens from `owner`,
         reducing the total supply.
    @notice Note that `owner` cannot be the
            zero address. Also, `owner` must
            have at least `amount` tokens.
    @param owner The 20-byte owner address.
    @param amount The 32-byte token amount to be destroyed.
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
    @dev Sets `amount` as the allowance of `spender`
         over the `owner`'s tokens.
    @notice Note that `owner` and `spender` cannot
            be the zero address.
    @param owner The 20-byte owner address.
    @param spender The 20-byte spender address.
    @param amount The 32-byte token amount that is
           allowed to be spent by the `spender`.
    """
    assert owner != empty(address), "ERC20: approve from the zero address"
    assert spender != empty(address), "ERC20: approve to the zero address"

    self.allowance[owner][spender] = amount
    log Approval(owner, spender, amount)


@internal
def _spend_allowance(owner: address, spender: address, amount: uint256):
    """
    @dev Updates `owner`'s allowance for `spender`
         based on spent `amount`.
    @notice WARNING: Note that it does not update the
            allowance `amount` in case of infinite
            allowance. Also, it reverts if not enough
            allowance is available.
    @param owner The 20-byte owner address.
    @param spender The 20-byte spender address.
    @param amount The 32-byte token amount that is
           allowed to be spent by the `spender`.
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
    @dev Hook that is called before any transfer of tokens.
         This includes minting and burning.
    @notice The calling conditions are:
            - when `owner` and `to` are both non-zero,
              `amount` of `owner`'s tokens will be
              transferred to `to`,
            - when `owner` is zero, `amount` tokens will
              be minted for `to`,
            - when `to` is zero, `amount` of `owner`'s
              tokens will be burned,
            - `owner` and `to` are never both zero.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount to be transferred.
    """
    pass


@internal
def _after_token_transfer(owner: address, to: address, amount: uint256):
    """
    @dev Hook that is called after any transfer of tokens.
         This includes minting and burning.
    @notice The calling conditions are:
            - when `owner` and `to` are both non-zero,
              `amount` of `owner`'s tokens has been
              transferred to `to`,
            - when `owner` is zero, `amount` tokens
              have been minted for `to`,
            - when `to` is zero, `amount` of `owner`'s
              tokens have been burned,
            - `owner` and `to` are never both zero.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount that has
           been transferred.
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
        return self._build_domain_separator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION)


@internal
@view
def _build_domain_separator(type_hash: bytes32, name_hash: bytes32, version_hash: bytes32) -> bytes32:
    """
    @dev Sourced from {EIP712DomainSeparator-_build_domain_separator}.
    @notice See {EIP712DomainSeparator-_build_domain_separator}
            for the function docstring.
    """
    return keccak256(_abi_encode(type_hash, name_hash, version_hash, chain.id, self))


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
    if (s > convert(_MALLEABILITY_THRESHOLD, uint256)):
        raise "ECDSA: invalid signature 's' value"

    signer: address = ecrecover(hash, v, r, s)
    if (signer == empty(address)):
        raise "ECDSA: invalid signature"
    
    return signer


@internal
@view
def _convert_to_shares(assets: uint256, rounding: Rounding) -> uint256:
    """
    @dev TBD
    """
    return self._mul_div(assets, self.totalSupply + 10 ** convert(_DECIMALS_OFFSET, uint256), ERC4626(self).totalAssets() + 1, rounding)


@internal
@pure
def _mul_div(x: uint256, y: uint256, denominator: uint256, rounding: Rounding) -> uint256:
    """
    @dev TBD
    """
    prod0: uint256 = empty(uint256)
    prod1: uint256 = empty(uint256)

    mm: uint256 = uint256_mulmod(x, y, ~empty(uint256))
    prod0 = unsafe_mul(x, y)
    if (mm < prod0):
        prod1 = unsafe_sub(unsafe_sub(mm, prod0), 1)
    else:
        prod1 = unsafe_sub(mm, prod0)

    if (prod1 == empty(uint256)):
        return unsafe_div(prod0, denominator)

    assert denominator > prod1, "Math: mul_div overflow"

    remainder: uint256 = uint256_mulmod(x, y, denominator)
    if (remainder > prod0):
        prod1 = unsafe_sub(prod1, 1)
    else:
        prod0 = unsafe_sub(prod0, remainder)

    twos: uint256 = denominator & (unsafe_add(~denominator, 1))
    denominator_div: uint256 = unsafe_div(denominator, twos)
    prod0 = unsafe_div(prod0, twos)
    twos = unsafe_add(unsafe_div(unsafe_sub(empty(uint256), twos), twos), 1)

    prod0 |= unsafe_mul(prod1, twos)

    inverse: uint256 = unsafe_mul(3, denominator_div) ^ 2
    
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^8
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^16
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^32
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^64
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^128
    inverse *= unsafe_sub(2, unsafe_mul(denominator_div, inverse)) # inverse mod 2^256

    result: uint256 = unsafe_mul(prod0, inverse)

    if (rounding == Rounding.UP and uint256_mulmod(x, y, denominator) > 0):
        return unsafe_add(result, 1)
    else:
        return result
