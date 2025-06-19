# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation
@custom:contract-name erc721
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions implement the ERC-721
        standard interface:
        - https://eips.ethereum.org/EIPS/eip-721.
        In addition, the following functions have
        been added for convenience:
        - `name` (`external` `view` function),
        - `symbol` (`external` `view` function),
        - `tokenURI` (`external` `view` function),
        - `totalSupply` (`external` `view` function),
        - `tokenByIndex` (`external` `view` function),
        - `tokenOfOwnerByIndex` (`external` `view` function),
        - `burn` (`external` function),
        - `is_minter` (`external` `view` function),
        - `safe_mint` (`external` function),
        - `set_minter` (`external` function),
        - `permit` (`external` function),
        - `nonces` (`external` `view` function),
        - `DOMAIN_SEPARATOR` (`external` `view` function),
        - `eip712Domain` (`external` `view` function),
        - `owner` (`external` `view` function),
        - `transfer_ownership` (`external` function),
        - `renounce_ownership` (`external` function),
        - `_check_on_erc721_received` (`internal` function),
        - `_before_token_transfer` (`internal` function),
        - `_after_token_transfer` (`internal` function).
        The `permit` function implements approvals via
        EIP-712 secp256k1 signatures for ERC-721 tokens:
        https://eips.ethereum.org/EIPS/eip-4494.
        In addition, this contract also implements the EIP-5267
        function `eip712Domain`:
        https://eips.ethereum.org/EIPS/eip-5267.
        Eventually, this contract also implements the EIP-4906
        metadata update extension:
        https://eips.ethereum.org/EIPS/eip-4906.
        The implementation is inspired by OpenZeppelin's
        implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol,
        as well as by ApeAcademy's implementation here:
        https://github.com/ApeAcademy/ERC721/blob/main/%7B%7Bcookiecutter.project_name%7D%7D/contracts/NFT.vy.
"""


# @dev We import and implement the `IERC165` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC165
implements: IERC165


# @dev We import and implement the `IERC721` interface,
# which is a built-in interface of the Vyper compiler.
from ethereum.ercs import IERC721
implements: IERC721


# @dev We import and implement the `IERC721Metadata`
# interface, which is written using standard Vyper
# syntax.
from .interfaces import IERC721Metadata
implements: IERC721Metadata


# @dev We import and implement the `IERC721Enumerable`
# interface, which is written using standard Vyper
# syntax.
from .interfaces import IERC721Enumerable
implements: IERC721Enumerable


# @dev We import and implement the `IERC721Permit`
# interface, which is written using standard Vyper
# syntax.
from .interfaces import IERC721Permit
implements: IERC721Permit


# @dev We import and implement the `IERC4906` interface,
# which is written using standard Vyper syntax.
from .interfaces import IERC4906
implements: IERC4906


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ..utils.interfaces import IERC5267
implements: IERC5267


# @dev We import the `IERC721Receiver` interface, which
# is written using standard Vyper syntax.
from .interfaces import IERC721Receiver


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
    # @notice This ERC-721 implementation includes the `transfer_ownership`
    # and `renounce_ownership` functions, which incorporate
    # the additional built-in `is_minter` role logic and are
    # therefore not exported from the `ownable` module.
    ownable.owner,
    eip712_domain_separator.eip712Domain,
)


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
# @notice If you are not using the full feature set of
# this contract, please ensure you exclude the unused
# ERC-165 interface identifiers in the main contract.
_SUPPORTED_INTERFACES: constant(bytes4[6]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0x80AC58CD, # The ERC-165 identifier for ERC-721.
    0x5B5E139F, # The ERC-165 identifier for the ERC-721 metadata extension.
    0x780E9D63, # The ERC-165 identifier for the ERC-721 enumeration extension.
    0x589C5CE2, # The ERC-165 identifier for ERC-4494.
    0x49064906, # The ERC-165 identifier for ERC-4906.
]


# @dev The 32-byte type hash of the `permit` function.
_PERMIT_TYPE_HASH: constant(bytes32) = keccak256(
    "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
)


# @dev Returns the token collection name.
# @notice If you declare a variable as `public`,
# Vyper automatically generates an `external`
# getter function for the variable. Furthermore,
# to preserve consistency with the interface for
# the optional metadata functions of the ERC-721
# standard, we use lower case letters for the
# `immutable` variables `name` and `symbol`.
name: public(immutable(String[25]))


# @dev Returns the token collection symbol.
# @notice See comment on lower case letters
# above at `name`.
symbol: public(immutable(String[5]))


# @dev Stores the base URI for computing `tokenURI`.
_BASE_URI: immutable(String[80])


# @dev Mapping from owner to operator approvals.
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])


# @dev Returns `True` if an `address` has been
# granted the minter role.
is_minter: public(HashMap[address, bool])


# @dev Returns the current on-chain tracked nonce
# of `token_id`.
nonces: public(HashMap[uint256, uint256])


# @dev Mapping from owner address to token count.
_balances: HashMap[address, uint256]


# @dev Mapping from token ID to owner address.
_owners: HashMap[uint256, address]


# @dev Mapping from token ID to approved address.
_token_approvals: HashMap[uint256, address]


# @dev Mapping from owner to list of owned token IDs.
_owned_tokens: HashMap[address, HashMap[uint256, uint256]]


# @dev Mapping from token ID to index of the owner
# tokens list.
_owned_tokens_index: HashMap[uint256, uint256]


# @dev Array with all token IDs used for enumeration.
_all_tokens: DynArray[uint256, max_value(uint64)]


# @dev Mapping from token ID to position in the
# `_all_tokens` array.
_all_tokens_index: HashMap[uint256, uint256]


# @dev Mapping from token ID to token URI.
# @notice Since the Vyper design requires
# strings of fixed size, we arbitrarily set
# the maximum length for `_token_uris` to 432
# characters. Since we have set the maximum
# length for `_BASE_URI` to 80 characters,
# which implies a maximum character length
# for `tokenURI` of 512.
_token_uris: HashMap[uint256, String[432]]


# @dev An `uint256` counter variable that sets
# the token ID for each `safe_mint` call and
# then increments.
_counter: uint256


# @dev Emitted when the status of a `minter`
# address is changed.
event RoleMinterChanged:
    minter: indexed(address)
    status: bool


@deploy
@payable
def __init__(
    name_: String[25], symbol_: String[5], base_uri_: String[80], name_eip712_: String[50], version_eip712_: String[20]
):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice At initialisation time, the `owner` role will be
            assigned to the `msg.sender` since we `uses` the
            `ownable` module, which implements the aforementioned
            logic at contract creation time.
    @param name_ The maximum 25-character user-readable string
           name of the token collection.
    @param symbol_ The maximum 5-character user-readable string
           symbol of the token collection.
    @param base_uri_ The maximum 80-character user-readable
           string base URI for computing `tokenURI`.
    @param name_eip712_ The maximum 50-character user-readable
           string name of the signing domain, i.e. the name
           of the dApp or protocol.
    @param version_eip712_ The maximum 20-character current
           main version of the signing domain. Signatures
           from different versions are not compatible.
    """
    self._counter = empty(uint256)

    name = name_
    symbol = symbol_
    _BASE_URI = base_uri_

    self.is_minter[msg.sender] = True
    log RoleMinterChanged(minter=msg.sender, status=True)

    eip712_domain_separator.__init__(name_eip712_, version_eip712_)


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
def balanceOf(owner: address) -> uint256:
    """
    @dev Returns the amount of tokens owned by `owner`.
    @notice Note that `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte token amount owned
            by `owner`.
    """
    return self._balance_of(owner)


@external
@view
def ownerOf(token_id: uint256) -> address:
    """
    @dev Returns the owner of the `token_id` token.
    @notice Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    @return address The 20-byte owner address.
    """
    return self._owner_of(token_id)


@external
@payable
def approve(to: address, token_id: uint256):
    """
    @dev Gives permission to `to` to transfer
         `token_id` token to another account.
         The approval is cleared when the token
         is transferred.
    @notice Only a single account can be approved
            at a time, so approving the zero address
            clears previous approvals. Also, the
            caller must own the token or be an
            approved operator, and `token_id` must
            exist.

            IMPORTANT: The function is declared as
            `payable` to comply with the EIP-721
            standard definition:
            https://eips.ethereum.org/EIPS/eip-721.
    @param to The 20-byte spender address.
    @param token_id The 32-byte identifier of the token.
    """
    owner: address = self._owner_of(token_id)
    assert to != owner, "erc721: approval to current owner"
    assert (
        msg.sender == owner or self.isApprovedForAll[owner][msg.sender]
    ), "erc721: approve caller is not token owner or approved for all"
    self._approve(to, token_id)


@external
@view
def getApproved(token_id: uint256) -> address:
    """
    @dev Returns the account approved for `token_id`
         token.
    @notice Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    @return address The 20-byte approved address.
    """
    return self._get_approved(token_id)


@external
def setApprovalForAll(operator: address, approved: bool):
    """
    @dev Approves or removes `operator` as an operator
         for the caller. Operators can call `transferFrom`
         or `safeTransferFrom` for any token owned by
         the caller.
    @notice Note that the `operator` cannot be the caller.
    @param operator The 20-byte operator address.
    @param approved The Boolean variable that sets the
           approval status.
    """
    self._set_approval_for_all(msg.sender, operator, approved)


@external
@payable
def transferFrom(owner: address, to: address, token_id: uint256):
    """
    @dev Transfers `token_id` token from `owner` to `to`.
    @notice WARNING: Note that the caller is responsible
            to confirm that the recipient is capable of
            receiving an ERC-721 token or else they may
            be permanently lost. Usage of `safeTransferFrom`
            prevents loss, though the caller must understand
            this adds an external call which potentially
            creates a reentrancy vulnerability.

            Note that `owner` and `to` cannot be the zero
            address. Also, `token_id` token must exist and
            must be owned by `owner`. Eventually, if the caller
            is not `owner`, it must be approved to move this
            token by either `approve` or `setApprovalForAll`.

            IMPORTANT: The function is declared as `payable`
            to comply with the EIP-721 standard definition:
            https://eips.ethereum.org/EIPS/eip-721.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    """
    assert self._is_approved_or_owner(msg.sender, token_id), "erc721: caller is not token owner or approved"
    self._transfer(owner, to, token_id)


@external
@payable
def safeTransferFrom(owner: address, to: address, token_id: uint256, data: Bytes[1_024] = b""):
    """
    @dev Safely transfers `token_id` token from `owner`
         to `to`.
    @notice Note that `owner` and `to` cannot be the zero
            address. Also, `token_id` token must exist and
            must be owned by `owner`. Furthermore, if the caller
            is not `owner`, it must be approved to move this
            token by either `approve` or `setApprovalForAll`.
            Eventually, if `to` refers to a smart contract,
            it must implement {IERC721Receiver-onERC721Received},
            which is called upon a safe transfer.

            The Vyper compiler processes this function `safeTransferFrom`
            as two separate function selectors, since a default
            parameter `b""` is set in the function declaration.
            Anyone can invoke this function using only `owner`,
            `to`, and `token_id` as arguments, and is therefore
            compatible with the function overloading of `safeTransferFrom`
            in the standard ERC-721 interface. You can find more
            information here:
            - https://github.com/vyperlang/vyper/issues/903,
            - https://github.com/vyperlang/vyper/pull/987.

            IMPORTANT: The function is declared as `payable`
            to comply with the EIP-721 standard definition:
            https://eips.ethereum.org/EIPS/eip-721.

            WARNING: This function can potentially allow a reentrancy
            attack when transferring tokens to an untrusted contract,
            when invoking {IERC721Receiver-onERC721Received} on the
            receiver. We ensure that we consistently follow the checks-
            effects-interactions (CEI) pattern to avoid being vulnerable
            to this type of attack.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    @param data The maximum 1,024-byte additional data
           with no specified format that is sent
           to `to`.
    """
    assert self._is_approved_or_owner(msg.sender, token_id), "erc721: caller is not token owner or approved"
    self._safe_transfer(owner, to, token_id, data)


@external
@view
def tokenURI(token_id: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for `token_id` token.
    @notice Throws if `token_id` is not a valid ERC-721 token.
    @param token_id The 32-byte identifier of the token.
    @return String The maximum 512-character user-readable
            string token URI of the `token_id` token.
    """
    self._require_minted(token_id)
    token_uri: String[432] = self._token_uris[token_id]

    base_uri_length: uint256 = len(_BASE_URI)
    # If there is no base URI, return the token URI.
    if base_uri_length == empty(uint256):
        return token_uri
    # If both are set, concatenate the base URI
    # and token URI.
    elif len(token_uri) != empty(uint256):
        return concat(_BASE_URI, token_uri)
    # If there is no token URI but a base URI,
    # concatenate the base URI and token ID.
    elif base_uri_length != empty(uint256):
        return concat(_BASE_URI, uint2str(token_id))

    return ""


@external
@view
def totalSupply() -> uint256:
    """
    @dev Returns the amount of tokens in existence.
    @return uint256 The 32-byte token supply.
    """
    return self._total_supply()


@external
@view
def tokenByIndex(index: uint256) -> uint256:
    """
    @dev Returns a token ID at a given `index` of
         all the tokens stored by the contract.
    @notice Use along with `totalSupply` to enumerate
            all tokens.
    @param index The 32-byte counter (must be less
           than `totalSupply`).
    @return uint256 The 32-byte token ID at index
            `index`.
    """
    assert index < self._total_supply(), "erc721: global index out of bounds"
    return self._all_tokens[index]


@external
@view
def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256:
    """
    @dev Returns a token ID owned by `owner` at a
         given `index` of its token list.
    @notice Use along with `balanceOf` to enumerate
            all of `owner`'s tokens.
    @param owner The 20-byte owner address.
    @param index The 32-byte counter (must be less
           than `balanceOf(owner)`).
    @return uint256 The 32-byte token ID owned by
            `owner` at index `index`.
    """
    assert index < self._balance_of(owner), "erc721: owner index out of bounds"
    return self._owned_tokens[owner][index]


@external
def burn(token_id: uint256):
    """
    @dev Burns the `token_id` token.
    @notice Note that the caller must own `token_id`
            or be an approved operator.
    @param token_id The 32-byte identifier of the token.
    """
    assert self._is_approved_or_owner(msg.sender, token_id), "erc721: caller is not token owner or approved"
    self._burn(token_id)


@external
def safe_mint(owner: address, uri: String[432]):
    """
    @dev Safely mints `token_id` and transfers it to `owner`.
    @notice Only authorised minters can access this function.
            Note that `owner` cannot be the zero address.
            Also, new tokens will be automatically assigned
            an incremental ID.
    @param owner The 20-byte owner address.
    @param uri The maximum 432-character user-readable
           string URI for computing `tokenURI`.
    """
    assert self.is_minter[msg.sender], "erc721: access is denied"
    # New tokens will be automatically assigned an incremental ID.
    # The first token ID will be zero.
    token_id: uint256 = self._counter
    self._counter = token_id + 1
    # Theoretically, the following line could overflow
    # if all 2**256 token IDs were minted. However,
    # since we have bounded the dynamic array `_all_tokens`
    # by the maximum value of `uint64` and the `_counter`
    # increments above are checked for an overflow, this is
    # no longer even theoretically possible.
    self._safe_mint(owner, token_id, b"")
    self._set_token_uri(token_id, uri)


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
    assert minter != empty(address), "erc721: minter is the zero address"
    # We ensured in the previous step `ownable._check_owner`
    # that `msg.sender` is the `owner`.
    assert minter != msg.sender, "erc721: minter is owner address"
    self.is_minter[minter] = status
    log RoleMinterChanged(minter=minter, status=status)


@external
def permit(spender: address, token_id: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32):
    """
    @dev Sets permission to `spender` to transfer `token_id`
         token to another account, given `owner`'s signed
         approval.
    @notice Note that `spender` cannot be the zero address.
            Also, `deadline` must be a block timestamp in
            the future. `v`, `r`, and `s` must be a valid
            secp256k1 signature from `owner` over the
            EIP-712-formatted function arguments. Eventually,
            the signature must use `token_id`'s current nonce.
    @param spender The 20-byte spender address.
    @param token_id The 32-byte identifier of the token.
    @param deadline The 32-byte block timestamp up
           which the `spender` is allowed to spend `token_id`.
    @param v The secp256k1 1-byte signature parameter `v`.
    @param r The secp256k1 32-byte signature parameter `r`.
    @param s The secp256k1 32-byte signature parameter `s`.
    """
    assert block.timestamp <= deadline, "erc721: expired deadline"

    current_nonce: uint256 = self.nonces[token_id]
    self.nonces[token_id] = unsafe_add(current_nonce, 1)

    struct_hash: bytes32 = keccak256(abi_encode(_PERMIT_TYPE_HASH, spender, token_id, current_nonce, deadline))
    hash: bytes32 = eip712_domain_separator._hash_typed_data_v4(struct_hash)

    signer: address = ecdsa._recover_vrs(hash, convert(v, uint256), convert(r, uint256), convert(s, uint256))
    assert signer == self._owner_of(token_id), "erc721: invalid signature"

    self._approve(spender, token_id)


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
    assert new_owner != empty(address), "erc721: new owner is the zero address"

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
@view
def _balance_of(owner: address) -> uint256:
    """
    @dev An `internal` helper function that returns the
         amount of tokens owned by `owner`.
    @notice Note that `owner` cannot be the zero address.
    @param owner The 20-byte owner address.
    @return uint256 The 32-byte token amount owned
            by `owner`.
    """
    assert owner != empty(address), "erc721: the zero address is not a valid owner"
    return self._balances[owner]


@internal
@view
def _owner_of(token_id: uint256) -> address:
    """
    @dev An `internal` helper function that returns the
         owner of the `token_id` token.
    @notice Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    @return address The 20-byte owner address.
    """
    owner: address = self._owners[token_id]
    assert owner != empty(address), "erc721: invalid token ID"
    return owner


@internal
@view
def _require_minted(token_id: uint256):
    """
    @dev Reverts if the `token_id` has not yet been minted.
    @param token_id The 32-byte identifier of the token.
    """
    assert self._exists(token_id), "erc721: invalid token ID"


@internal
@view
def _exists(token_id: uint256) -> bool:
    """
    @dev Returns whether `token_id` exists.
    @notice Tokens can be managed by their owner or approved
            accounts via `approve` or `setApprovalForAll`.
            Tokens start existing when they are minted (`_mint`),
            and stop existing when they are burned (`_burn`).
    @param token_id The 32-byte identifier of the token.
    @return bool The verification whether `token_id` exists
            or not.
    """
    return self._owners[token_id] != empty(address)


@internal
def _approve(to: address, token_id: uint256):
    """
    @dev Approves `to` to operate on `token_id`.
    @param to The 20-byte spender address.
    @param token_id The 32-byte identifier of the token.
    """
    self._token_approvals[token_id] = to
    log IERC721.Approval(owner=self._owner_of(token_id), approved=to, token_id=token_id)


@internal
@view
def _get_approved(token_id: uint256) -> address:
    """
    @dev An `internal` helper function that returns the
         account approved for `token_id` token.
    @notice Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    @return address The 20-byte approved address.
    """
    self._require_minted(token_id)
    return self._token_approvals[token_id]


@internal
def _set_approval_for_all(owner: address, operator: address, approved: bool):
    """
    @dev Approves `operator` to operate on all of `owner` tokens.
    @param owner The 20-byte owner address.
    @param operator The 20-byte operator address.
    @param approved The Boolean variable that sets the
           approval status.
    """
    assert owner != operator, "erc721: approve to caller"
    self.isApprovedForAll[owner][operator] = approved
    log IERC721.ApprovalForAll(owner=owner, operator=operator, approved=approved)


@internal
def _is_approved_or_owner(spender: address, token_id: uint256) -> bool:
    """
    @dev Returns whether `spender` is allowed to manage
         `token_id`.
    @notice Note that `token_id` must exist.
    @param spender The 20-byte spender address.
    @param token_id The 32-byte identifier of the token.
    """
    owner: address = self._owner_of(token_id)
    return ((spender == owner) or (self.isApprovedForAll[owner][spender]) or (self._get_approved(token_id) == spender))


@internal
def _safe_mint(owner: address, token_id: uint256, data: Bytes[1_024]):
    """
    @dev Safely mints `token_id` and transfers it to `owner`.
    @notice Note that `token_id` must not exist. Also, if `owner`
            refers to a smart contract, it must implement
            {IERC721Receiver-onERC721Received}, which is called
            upon a safe transfer.

            WARNING: This `internal` function without access
            restriction can potentially allow a reentrancy
            attack when transferring tokens to an untrusted
            contract, when invoking {IERC721Receiver-onERC721Received}
            on the receiver. We ensure that we consistently
            follow the checks-effects-interactions (CEI) pattern
            to avoid being vulnerable to this type of attack.
    @param owner The 20-byte owner address.
    @param token_id The 32-byte identifier of the token.
    @param data The maximum 1,024-byte additional data
           with no specified format that is sent
           to `owner`.
    """
    self._mint(owner, token_id)
    assert self._check_on_erc721_received(
        empty(address), owner, token_id, data
    ), "erc721: transfer to non-IERC721Receiver implementer"


@internal
def _mint(owner: address, token_id: uint256):
    """
    @dev Mints `token_id` and transfers it to `owner`.
    @notice Note that `token_id` must not exist and
            `owner` cannot be the zero address.

            WARNING: Usage of this method is discouraged,
            use `_safe_mint` whenever possible.
    @param owner The 20-byte owner address.
    @param token_id The 32-byte identifier of the token.
    """
    assert owner != empty(address), "erc721: mint to the zero address"
    assert not self._exists(token_id), "erc721: token already minted"

    self._before_token_transfer(empty(address), owner, token_id)
    # Checks that the `token_id` was not minted by the
    # `_before_token_transfer` hook.
    assert not self._exists(token_id), "erc721: token already minted"

    # Theoretically, the following line could overflow
    # if all 2**256 token IDs were minted to the same owner.
    # However, since we have bounded the dynamic array
    # `_all_tokens` by the maximum value of `uint64`,
    # this is no longer even theoretically possible.
    self._balances[owner] = unsafe_add(self._balances[owner], 1)
    self._owners[token_id] = owner
    log IERC721.Transfer(sender=empty(address), receiver=owner, token_id=token_id)

    self._after_token_transfer(empty(address), owner, token_id)


@internal
def _safe_transfer(owner: address, to: address, token_id: uint256, data: Bytes[1_024]):
    """
    @dev Safely transfers `token_id` token from
         `owner` to `to`, checking first that contract
         recipients are aware of the ERC-721 protocol
         to prevent tokens from being forever locked.
    @notice This `internal` function is equivalent to
            `safeTransferFrom`, and can be used to e.g.
            implement alternative mechanisms to perform
            token transfers, such as signature-based.

            Note that `owner` and `to` cannot be the zero
            address. Also, `token_id` token must exist and
            must be owned by `owner`. Eventually, if `to`
            refers to a smart contract, it must implement
            {IERC721Receiver-onERC721Received}, which is
            called upon a safe transfer.

            WARNING: This `internal` function can potentially
            allow a reentrancy attack when transferring tokens
            to an untrusted contract, when invoking {IERC721Receiver-onERC721Received}
            on the receiver. We ensure that we consistently
            follow the checks-effects-interactions (CEI) pattern
            to avoid being vulnerable to this type of attack.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    @param data The maximum 1,024-byte additional data
           with no specified format that is sent
           to `to`.
    """
    self._transfer(owner, to, token_id)
    assert self._check_on_erc721_received(
        owner, to, token_id, data
    ), "erc721: transfer to non-IERC721Receiver implementer"


@internal
def _transfer(owner: address, to: address, token_id: uint256):
    """
    @dev Transfers `token_id` from `owner` to `to`.
         As opposed to `transferFrom`, this imposes
         no restrictions on `msg.sender`.
    @notice Note that `to` cannot be the zero address.
            Also, `token_id` token must be owned by
            `owner`.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    """
    assert self._owner_of(token_id) == owner, "erc721: transfer from incorrect owner"
    assert to != empty(address), "erc721: transfer to the zero address"

    self._before_token_transfer(owner, to, token_id)
    # Checks that the `token_id` was not transferred by the
    # `_before_token_transfer` hook.
    assert self._owner_of(token_id) == owner, "erc721: transfer from incorrect owner"

    self._token_approvals[token_id] = empty(address)
    # See comment why an overflow is not possible in the
    # following two lines above at `_mint`.
    self._balances[owner] = unsafe_sub(self._balances[owner], 1)
    self._balances[to] = unsafe_add(self._balances[to], 1)
    self._owners[token_id] = to
    log IERC721.Transfer(sender=owner, receiver=to, token_id=token_id)

    self._after_token_transfer(owner, to, token_id)


@internal
def _set_token_uri(token_id: uint256, token_uri: String[432]):
    """
    @dev Sets `token_uri` as the token URI of `token_id`.
    @notice Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    @param token_uri The maximum 432-character user-readable
           string URI for computing `tokenURI`.
    """
    assert self._exists(token_id), "erc721: URI set of nonexistent token"
    self._token_uris[token_id] = token_uri
    log IERC4906.MetadataUpdate(_tokenId=token_id)


@internal
@view
def _total_supply() -> uint256:
    """
    @dev An `internal` helper function that returns the amount
         of tokens in existence.
    @return uint256 The 32-byte token supply.
    """
    return len(self._all_tokens)


@internal
def _burn(token_id: uint256):
    """
    @dev Destroys `token_id`.
    @notice The approval is cleared when the token is burned.
            This is an `internal` function that does not check
            if the sender is authorised to operate on the token.
            Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    """
    owner: address = self._owner_of(token_id)

    self._before_token_transfer(owner, empty(address), token_id)
    # Updates ownership in case the `token_id` was
    # transferred by the `_before_token_transfer` hook.
    owner = self._owner_of(token_id)

    self._token_approvals[token_id] = empty(address)
    # Overflow is not possible, as in this case more tokens would
    # have to be burned/transferred than the owner originally
    # received through minting and transfer.
    self._balances[owner] = unsafe_sub(self._balances[owner], 1)
    self._owners[token_id] = empty(address)
    log IERC721.Transfer(sender=owner, receiver=empty(address), token_id=token_id)

    self._after_token_transfer(owner, empty(address), token_id)

    # Checks whether a token-specific URI has been set for the token
    # and deletes the token URI from the storage mapping.
    if len(self._token_uris[token_id]) != empty(uint256):
        self._token_uris[token_id] = ""


@internal
def _check_on_erc721_received(owner: address, to: address, token_id: uint256, data: Bytes[1_024]) -> bool:
    """
    @dev An `internal` function that invokes {IERC721Receiver-onERC721Received}
         on a target address. The call is not executed
         if the target address is not a contract.
    @param owner The 20-byte address which previously
           owned the token.
    @param to The 20-byte address receiver address.
    @param token_id The 32-byte identifier of the token.
    @param data The maximum 1,024-byte additional data
           with no specified format.
    @return bool The verification whether the call correctly
            returned the expected magic value.
    """
    # Contract case.
    if to.is_contract:
        return_value: bytes4 = extcall IERC721Receiver(to).onERC721Received(msg.sender, owner, token_id, data)
        assert return_value == method_id(
            "onERC721Received(address,address,uint256,bytes)", output_type=bytes4
        ), "erc721: transfer to non-IERC721Receiver implementer"
        return True

    # EOA case.
    return True


@internal
def _before_token_transfer(owner: address, to: address, token_id: uint256):
    """
    @dev Hook that is called before any token transfer.
         This includes minting and burning.
    @notice The calling conditions are:
            - when `owner` and `to` are both non-zero,
              `owner`'s tokens will be transferred to `to`,
            - when `owner` is zero, the tokens will
              be minted for `to`,
            - when `to` is zero, `owner`'s tokens will
              be burned,
            - `owner` and `to` are never both zero.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    """
    if owner == empty(address):
        self._add_token_to_all_tokens_enumeration(token_id)
    elif owner != to:
        self._remove_token_from_owner_enumeration(owner, token_id)

    if to == empty(address):
        self._remove_token_from_all_tokens_enumeration(token_id)
    elif to != owner:
        self._add_token_to_owner_enumeration(to, token_id)


@internal
def _after_token_transfer(owner: address, to: address, token_id: uint256):
    """
    @dev Hook that is called after any token transfer.
         This includes minting and burning.
    @notice The calling conditions are:
            - when `owner` and `to` are both non-zero,
              `owner`'s tokens were transferred to `to`,
            - when `owner` is zero, the tokens were
              be minted for `to`,
            - when `to` is zero, `owner`'s tokens will
              be burned,
            - `owner` and `to` are never both zero.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    """
    pass


@internal
def _add_token_to_owner_enumeration(to: address, token_id: uint256):
    """
    @dev This is an `internal` function that adds a token
         to the ownership-tracking data structures.
    @param to The 20-byte receiver address.
    @param token_id The 32-byte identifier of the token.
    """
    length: uint256 = self._balance_of(to)
    self._owned_tokens[to][length] = token_id
    self._owned_tokens_index[token_id] = length


@internal
def _add_token_to_all_tokens_enumeration(token_id: uint256):
    """
    @dev This is an `internal` function that adds a token
         to the token tracking data structures.
    @param token_id The 32-byte identifier of the token.
    """
    self._all_tokens_index[token_id] = len(self._all_tokens)
    self._all_tokens.append(token_id)


@internal
def _remove_token_from_owner_enumeration(owner: address, token_id: uint256):
    """
    @dev This is an `internal` function that removes a token
         from the ownership-tracking data structures.
    @notice Note that while the token is not assigned a new
            owner, the `_owned_tokens_index` mapping is NOT
            updated: this allows for gas optimisations e.g.
            when performing a transfer operation (avoiding
            double writes). This function has O(1) time
            complexity, but alters the order of the
            `_owned_tokens` array.
    @param owner The 20-byte owner address.
    @param token_id The 32-byte identifier of the token.
    """
    # To prevent a gap in `owner`'s tokens array,
    # we store the last token in the index of the
    # token to delete, and then delete the last slot.
    last_token_index: uint256 = self._balance_of(owner) - 1
    token_index: uint256 = self._owned_tokens_index[token_id]

    # When the token to delete is the last token,
    # the swap operation is unnecessary.
    if token_index != last_token_index:
        last_token_id: uint256 = self._owned_tokens[owner][last_token_index]
        # Moves the last token to the slot of the to-delete token.
        self._owned_tokens[owner][token_index] = last_token_id
        # Updates the moved token's index.
        self._owned_tokens_index[last_token_id] = token_index

    # This also deletes the contents at the
    # last position of the array.
    self._owned_tokens_index[token_id] = empty(uint256)
    self._owned_tokens[owner][last_token_index] = empty(uint256)


@internal
def _remove_token_from_all_tokens_enumeration(token_id: uint256):
    """
    @dev This is an `internal` function that removes a token
         from the token tracking data structures.
    @notice This function has O(1) time complexity, but
            alters the order of the `_all_tokens` array.
    @param token_id The 32-byte identifier of the token.
    """
    # To prevent a gap in the tokens array,
    # we store the last token in the index
    # of the token to delete, and then delete
    # the last slot.
    last_token_index: uint256 = len(self._all_tokens) - 1
    token_index: uint256 = self._all_tokens_index[token_id]

    # When the token to delete is the last token,
    # the swap operation is unnecessary. However,
    # since this occurs so rarely (when the last
    # minted token is burned) that we still do the
    # swap here to avoid the gas cost of adding
    # an `if` statement (like in `_remove_token_from_owner_enumeration`).
    last_token_id: uint256 = self._all_tokens[last_token_index]

    # Moves the last token to the slot of the to-delete token.
    self._all_tokens[token_index] = last_token_id
    # Updates the moved token's index.
    self._all_tokens_index[last_token_id] = token_index

    # This also deletes the contents at the
    # last position of the array.
    self._all_tokens_index[token_id] = empty(uint256)
    self._all_tokens.pop()
