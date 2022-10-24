# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-20 + EIP-2612 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions implement the ERC-20 standard interface:
        - https://eips.ethereum.org/EIPS/eip-20.
        In addition, the following functions have been added
        for convenience:
        - `increase_allowance` (`external` function),
        - `decrease_allowance` (`external` function),
        - `burn` (`external` function),
        - `burn_from` (`external` function),
        - `permit` (`external` function),
        - `mint` (`external` function),
        - `add_minter` (`external` function),
        - `remove_minter` (`external` function),
        - `transfer_ownership` (`external` function),
        - `renounce_ownership` (`external` function),
        - `_before_token_transfer` (`internal` function),
        - `_after_token_transfer` (`internal` function).
        The `permit` function implements approvals via EIP-712
        secp256k1 signatures:
        https://eips.ethereum.org/EIPS/eip-2612.
        The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol.
"""


# @dev We do not import the interface `ERC20Detailed`
# (https://github.com/vyperlang/vyper/blob/master/vyper/builtin_interfaces/ERC20Detailed.py)
# to be able to declare `name`, `symbol`, and `decimals`
# as `immutable` and `constant` variables.
from vyper.interfaces import ERC20
implements: ERC20


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


# @dev Emitted when the ownership is transferred
# from `previous_owner` to `new_owner`.
event OwnershipTransferred:
    previous_owner: indexed(address)
    new_owner: indexed(address)


# @dev Returns the decimals places of the token.
# The default value is 18.
# @notice If you declare a variable as public,
# Vyper automatically generates an `external`
# getter function for the variable.
decimals: public(constant(uint8)) = 18


# @dev Returns the name of the token.
name: public(immutable(String[25]))


# @dev Returns the symbol of the token.
symbol: public(immutable(String[5]))


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


# @dev Returns the address of the current owner.
owner: public(address)


# @dev Returns `True` if an `address` has been granted the minter role.
is_minter: public(HashMap[address, bool])


@external
@payable
def __init__(name_: String[25], symbol_: String[5]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    msg_sender: address = msg.sender
    self._transfer_ownership(msg_sender)
    self.is_minter[msg_sender] = True
    name = name_
    symbol = symbol_


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
    @notice Note that if `amount` is the maximum `uint256`,
            the allowance is not updated on `transferFrom`.
            This is semantically equivalent to an infinite
            approval. Also, `spender` cannot be the zero
            address.

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

            IMPORTANT: The function does not update the
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
    owner: address = msg.sender
    self._approve(owner, spender, self.allowance[owner][spender] + added_amount)
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
    owner: address = msg.sender
    current_allowance: uint256 = self.allowance[owner][spender]
    assert current_allowance >= subtracted_amount, "ERC20: decreased allowance below zero"
    self._approve(owner, spender, unsafe_sub(current_allowance, subtracted_amount))
    return True


@external
def mint(owner: address, amount: uint256):
    """
    @dev Creates `amount` tokens and assigns them to `owner`.
    @notice Only authorised minters can access this function.
            Note that `owner` cannot be the zero address.
    @param amount The 32-byte token amount to be created.
    """
    assert self.is_minter[msg.sender], "AccessControl: Access is denied"
    self._mint(owner, amount)


@external
def add_minter(minter: address):
    """
    @dev Adds a new `minter` address to the list of allowed
         minters. Note that only the `owner` can add new minters.
         Also, the new `minter` cannot be the zero address.
    @param minter The 20-byte minter address.
    """
    self._check_owner()
    assert minter != empty(address), "AccessControl: new minter is the zero address"
    self.is_minter[minter] = True


@external
def remove_minter(minter: address):
    """
    @dev Removes an existing `minter` address from the list of allowed
         minters. Note that only the `owner` can remove minters. Also,
         the `owner` cannot remove himself from the list of allowed
         minters.
    @param minter The 20-byte minter address.
    """
    self._check_owner()
    assert minter != self.owner, "AccessControl: removed minter is owner address"
    self.is_minter[minter] = False


@external
def transfer_ownership(new_owner: address):
    """
    @dev Transfers the ownership of the contract
         to a new account `new_owner`.
    @notice Note that this function can only be
            called by the current `owner`. Also,
            the `new_owner` cannot be the zero address.
    @param new_owner The 20-byte address of the new owner.
    """
    self._check_owner()
    assert new_owner != empty(address), "AccessControl: new owner is the zero address"
    self._transfer_ownership(new_owner)


@external
def renounce_ownership():
    """
    @dev Leaves the contract without owner.
    @notice Renouncing ownership will leave
            the contract without an owner,
            thereby removing any functionality
            that is only available to the owner.
            Notice, that the `owner` is also
            removed from the list of allowed
            minters.
    """
    self._check_owner()
    self.is_minter[msg.sender] = False
    self._transfer_ownership(empty(address))


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
    @notice Note that `owner` cannot be the
            zero address.
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
    @notice Note that it does not update the allowance
            `amount` in case of infinite allowance.
            Also, it reverts if not enough allowance
            is available.
    @param owner The 20-byte owner address.
    @param spender The 20-byte spender address.
    @param amount The 32-byte token amount that is
           allowed to be spent by the `spender`.
    """
    current_allowance: uint256 = self.allowance[owner][spender]
    if (current_allowance != max_value(uint256)):
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
def _check_owner():
    """
    @dev Throws if the sender is not the owner.
    """
    assert msg.sender == self.owner, "AccessControl: caller is not the owner"


@internal
def _transfer_ownership(new_owner: address):
    """
    @dev Transfers the ownership of the contract
         to a new account `new_owner`.
    @notice Internal function without access
            restriction.
    @param new_owner The 20-byte address of the new owner.
    """
    old_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(old_owner, new_owner)
