# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Modern and Gas-Efficient ERC-20 + EIP-2612 Implementation
@custom:contract-name erc20
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions implement the ERC-20
        standard interface:
        - https://eips.ethereum.org/EIPS/eip-20.
        In addition, the following functions have
        been added for convenience:
        - `name` (`external` `view` function),
        - `symbol` (`external` `view` function),
        - `decimals` (`external` `view` function),
        - `burn` (`external` function),
        - `burn_from` (`external` function),
        - `is_minter` (`external` `view` function),
        - `mint` (`external` function),
        - `set_minter` (`external` function),
        - `permit` (`external` function),
        - `nonces` (`external` `view` function),
        - `DOMAIN_SEPARATOR` (`external` `view` function),
        - `eip712Domain` (`external` `view` function),
        - `owner` (`external` `view` function),
        - `transfer_ownership` (`external` function),
        - `renounce_ownership` (`external` function),
        - `_before_token_transfer` (`internal` function),
        - `_after_token_transfer` (`internal` function).
        The `permit` function implements approvals via
        EIP-712 secp256k1 signatures:
        https://eips.ethereum.org/EIPS/eip-2612.
        In addition, this contract also implements the EIP-5267
        function `eip712Domain`:
        https://eips.ethereum.org/EIPS/eip-5267.
        The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol,
        as well as by ApeAcademy's implementation here:
        https://github.com/ApeAcademy/ERC20/blob/main/%7B%7Bcookiecutter.project_name%7D%7D/contracts/Token.vy.
@custom:security This ERC-20 implementation allows the commonly known
                 address poisoning attack, where `transferFrom` instructions
                 are executed from arbitrary addresses with an `amount` of `0`.
                 However, this poisoning attack is not an on-chain vulnerability.
                 All assets are safe. It is an off-chain log interpretation issue.
                 The main reason why we do not disallow address poisonig is that
                 we do not want to potentially break any DeFi composability.
                 This issue has been extensively discussed here:
                 https://github.com/pcaversaccio/snekmate/issues/51,
                 as well as in the OpenZeppelin repository:
                 https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3931.
"""


# @dev We import and implement the `IERC20` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC20
implements: IERC20


# @dev We import and implement the `IERC20Detailed` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC20Detailed
implements: IERC20Detailed


# @dev We import and implement the `IERC20Permit`
# interface, which is written using standard Vyper
# syntax.
from .interfaces import IERC20Permit
implements: IERC20Permit


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ..utils.interfaces import IERC5267
implements: IERC5267


# @dev We import and use the `ownable` module.
from ..auth import ownable
uses: ownable


# @dev We import the `ecdsa` module.
# @notice Please note that the `ecdsa` module
# is stateless and therefore does not require
# the `uses` keyword for usage.
from ..utils import ecdsa


# @dev We import and initialise the `eip712_domain_separator` module.
from ..utils import eip712_domain_separator
initializes: eip712_domain_separator


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) the `external` getter
# function `owner` from the `ownable` module as well as the
# function `eip712Domain` from the `eip712_domain_separator`
# module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: (
    # @notice This ERC-20 implementation includes the `transfer_ownership`
    # and `renounce_ownership` functions, which incorporate
    # the additional built-in `is_minter` role logic and are
    # therefore not exported from the `ownable` module.
    ownable.owner,
    eip712_domain_separator.eip712Domain,
)


# @dev The 32-byte type hash of the `permit` function.
_PERMIT_TYPE_HASH: constant(bytes32) = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
)


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


# @dev Returns the decimal places of the token.
# @notice See comment on lower case letters
# above at `name`.
decimals: public(immutable(uint8))


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


# @dev Returns `True` if an `address` has been
# granted the minter role.
is_minter: public(HashMap[address, bool])


# @dev Returns the current on-chain tracked nonce
# of `address`.
nonces: public(HashMap[address, uint256])


# @dev Emitted when the status of a `minter`
# address is changed.
event RoleMinterChanged:
    minter: indexed(address)
    status: bool


@deploy
@payable
def __init__(
    name_: String[25], symbol_: String[5], decimals_: uint8, name_eip712_: String[50], version_eip712_: String[20]
):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice At initialisation time, the `owner` role will be
            assigned to the `msg.sender` since we `uses` the
            `ownable` module, which implements the aforementioned
            logic at contract creation time.
    @param name_ The maximum 25-character user-readable
           string name of the token.
    @param symbol_ The maximum 5-character user-readable
           string symbol of the token.
    @param decimals_ The 1-byte decimal places of the token.
    @param name_eip712_ The maximum 50-character user-readable
           string name of the signing domain, i.e. the name
           of the dApp or protocol.
    @param version_eip712_ The maximum 20-character current
           main version of the signing domain. Signatures
           from different versions are not compatible.
    """
    name = name_
    symbol = symbol_
    decimals = decimals_

    self.is_minter[msg.sender] = True
    log RoleMinterChanged(minter=msg.sender, status=True)

    eip712_domain_separator.__init__(name_eip712_, version_eip712_)


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
            first reduce the spender's allowance to `0` and
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
def burn(amount: uint256):
    """
    @dev Destroys `amount` tokens from the caller.
    @param amount The 32-byte token amount to be destroyed.
    """
    self._burn(msg.sender, amount)


@external
def burn_from(owner: address, amount: uint256):
    """
    @dev Destroys `amount` tokens from `owner`,
         deducting from the caller's allowance.
    @notice Note that `owner` cannot be the
            zero address. Also, the caller must
            have an allowance for `owner`'s tokens
            of at least `amount`.
    @param owner The 20-byte owner address.
    @param amount The 32-byte token amount to be destroyed.
    """
    self._spend_allowance(owner, msg.sender, amount)
    self._burn(owner, amount)


@external
def mint(owner: address, amount: uint256):
    """
    @dev Creates `amount` tokens and assigns them to `owner`.
    @notice Only authorised minters can access this function.
            Note that `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @param amount The 32-byte token amount to be created.
    """
    assert self.is_minter[msg.sender], "erc20: access is denied"
    self._mint(owner, amount)


@external
def set_minter(minter: address, status: bool):
    """
    @dev Adds or removes an address `minter` to/from the
         list of allowed minters. Note that only the
         `owner` can add or remove `minter` addresses.
         Also, the `minter` cannot be the zero address.
         Eventually, the `owner` cannot remove himself
         from the list of allowed minters.
    @param minter The 20-byte minter address.
    @param status The Boolean variable that sets the status.
    """
    ownable._check_owner()
    assert minter != empty(address), "erc20: minter is the zero address"
    # We ensured in the previous step `ownable._check_owner`
    # that `msg.sender` is the `owner`.
    assert minter != msg.sender, "erc20: minter is owner address"
    self.is_minter[minter] = status
    log RoleMinterChanged(minter=minter, status=status)


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
    assert block.timestamp <= deadline, "erc20: expired deadline"

    current_nonce: uint256 = self.nonces[owner]
    self.nonces[owner] = unsafe_add(current_nonce, 1)

    struct_hash: bytes32 = keccak256(abi_encode(_PERMIT_TYPE_HASH, owner, spender, amount, current_nonce, deadline))
    hash: bytes32 = eip712_domain_separator._hash_typed_data_v4(struct_hash)

    signer: address = ecdsa._recover_vrs(hash, convert(v, uint256), convert(r, uint256), convert(s, uint256))
    assert signer == owner, "erc20: invalid signature"

    self._approve(owner, spender, amount)


@external
@view
def DOMAIN_SEPARATOR() -> bytes32:
    """
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    return eip712_domain_separator._domain_separator_v4()


@external
def transfer_ownership(new_owner: address):
    """
    @dev Transfers the ownership of the contract
         to a new account `new_owner`.
    @notice Note that this function can only be
            called by the current `owner`. Also,
            the `new_owner` cannot be the zero address.

            WARNING: The ownership transfer also removes
            the previous owner's minter role and assigns
            the minter role to `new_owner` accordingly.
    @param new_owner The 20-byte address of the new owner.
    """
    ownable._check_owner()
    assert new_owner != empty(address), "erc20: new owner is the zero address"

    self.is_minter[msg.sender] = False
    log RoleMinterChanged(minter=msg.sender, status=False)

    ownable._transfer_ownership(new_owner)
    self.is_minter[new_owner] = True
    log RoleMinterChanged(minter=new_owner, status=True)


@external
def renounce_ownership():
    """
    @dev Leaves the contract without an owner.
    @notice Renouncing ownership will leave the
            contract without an owner, thereby
            removing any functionality that is
            only available to the owner. Note
            that the `owner` is also removed from
            the list of allowed minters.

            WARNING: All other existing `minter`
            addresses will still be able to create
            new tokens. Consider removing all non-owner
            minter addresses first via `set_minter`
            before calling `renounce_ownership`.
    """
    ownable._check_owner()
    self.is_minter[msg.sender] = False
    log RoleMinterChanged(minter=msg.sender, status=False)
    ownable._transfer_ownership(empty(address))


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
    assert owner != empty(address), "erc20: transfer from the zero address"
    assert to != empty(address), "erc20: transfer to the zero address"

    self._before_token_transfer(owner, to, amount)

    owner_balanceOf: uint256 = self.balanceOf[owner]
    assert owner_balanceOf >= amount, "erc20: transfer amount exceeds balance"
    self.balanceOf[owner] = unsafe_sub(owner_balanceOf, amount)
    self.balanceOf[to] = unsafe_add(self.balanceOf[to], amount)
    log IERC20.Transfer(sender=owner, receiver=to, value=amount)

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
    assert owner != empty(address), "erc20: mint to the zero address"

    self._before_token_transfer(empty(address), owner, amount)

    self.totalSupply += amount
    self.balanceOf[owner] = unsafe_add(self.balanceOf[owner], amount)
    log IERC20.Transfer(sender=empty(address), receiver=owner, value=amount)

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
    assert owner != empty(address), "erc20: burn from the zero address"

    self._before_token_transfer(owner, empty(address), amount)

    account_balance: uint256 = self.balanceOf[owner]
    assert account_balance >= amount, "erc20: burn amount exceeds balance"
    self.balanceOf[owner] = unsafe_sub(account_balance, amount)
    self.totalSupply = unsafe_sub(self.totalSupply, amount)
    log IERC20.Transfer(sender=owner, receiver=empty(address), value=amount)

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
    assert owner != empty(address), "erc20: approve from the zero address"
    assert spender != empty(address), "erc20: approve to the zero address"

    self.allowance[owner][spender] = amount
    log IERC20.Approval(owner=owner, spender=spender, value=amount)


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
    if current_allowance < max_value(uint256):
        # The following line allows the commonly known address
        # poisoning attack, where `transferFrom` instructions
        # are executed from arbitrary addresses with an `amount`
        # of `0`. However, this poisoning attack is not an on-chain
        # vulnerability. All assets are safe. It is an off-chain
        # log interpretation issue.
        assert current_allowance >= amount, "erc20: insufficient allowance"
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
