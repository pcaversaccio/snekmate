# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `ERC721` interface,
# which is a built-in interface of the Vyper compiler.
# @notice We do not import the interface `IERC721Metadata`
# (https://github.com/pcaversaccio/snekmate/blob/main/src/tokens/interfaces/IERC721Metadata.vy)
# to be able to declare `name` and `symbol` as
# `immutable` variables. This is a known compiler
# bug (https://github.com/vyperlang/vyper/issues/3130)
# and we will import the interface `IERC721Metadata`
# once it is fixed.
from vyper.interfaces import ERC721
implements: ERC721


# @dev We import and implement the `IERC721Enumerable`
# interface, which is written using standard Vyper
# syntax.
import interfaces.IERC721Enumerable as IERC721Enumerable
implements: IERC721Enumerable


# @dev We import and implement the `IERC721Permit`
# interface, which is written using standard Vyper
# syntax.
import interfaces.IERC721Permit as IERC721Permit
implements: IERC721Permit


# @dev We import the `IERC721Receiver` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC721Receiver as IERC721Receiver


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[5]) = [
    0x01ffc9a7, # The ERC-165 identifier for ERC-165.
    0x80ac58cd, # The ERC-165 identifier for ERC-721.
    0x5b5e139f, # The ERC-165 identifier for ERC-721 metadata extension.
    0x780e9d63, # The ERC-165 identifier for ERC-721 enumeration extension.
    0x589c5ce2, # The ERC-165 identifier for ERC-4494.
]


# @dev Constant used as part of the ECDSA recovery function.
_MALLEABILITY_THRESHOLD: constant(bytes32) = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0


# @dev The 32-byte type hash of the `permit` function.
_PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)")


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
_BASE_URI: immutable(String[25])


# @dev Cache the domain separator as an `immutable`
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


# @dev Mapping from owner to operator approvals.
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])


# @dev Returns the address of the current owner.
owner: public(address)


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
_token_uris: HashMap[uint256, String[350]]


# @dev Emitted when `token_id` token is
# transferred from `owner` to `to`.
event Transfer:
    owner: indexed(address)
    to: indexed(address)
    token_id: indexed(uint256)


# @dev Emitted when `owner` enables `approved`
# to manage the `token_id` token.
event Approval:
    owner: indexed(address)
    approved: indexed(address)
    token_id: indexed(uint256)


# @dev Emitted when `owner` enables or disables
# (`approved`) `operator` to manage all of its
# assets.
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


# @dev Emitted when the ownership is transferred
# from `previous_owner` to `new_owner`.
event OwnershipTransferred:
    previous_owner: indexed(address)
    new_owner: indexed(address)


# @dev Emitted when the status of a `minter`
# address is changed.
event RoleMinterChanged:
    minter: indexed(address)
    status: bool


@external
@payable
def __init__(name_: String[25], symbol_: String[5], base_uri_: String[25], name_eip712_: String[50], version_eip712_: String[20]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice TBD
    @param name_ The maximum 25-byte user-readable string
           name of the token collection.
    @param symbol_ The maximum 5-byte user-readable string
           symbol of the token collection.
    @param base_uri_ The maximum 25-byte user-readable string
            base URI for computing `tokenURI`.
    @param name_eip712_ The maximum 50-byte user-readable
           string name of the signing domain, i.e. the name
           of the dApp or protocol.
    @param version_eip712_ The maximum 20-byte current main
           version of the signing domain. Signatures from
           different versions are not compatible.
    """
    name = name_
    symbol = symbol_
    _BASE_URI = base_uri_

    self._transfer_ownership(msg.sender)
    self.is_minter[msg.sender] = True

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
@pure
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns true if this contract implements the
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
    assert owner != empty(address), "ERC721: the zero address is not a valid owner"
    return self._balances[owner]


@external
@view
def ownerOf(token_id: uint256) -> address:
    """
    @dev Returns the owner of the `token_id` token.
    @notice Note that `token_id` must exist.
    @param token_id The 32-byte identifier of the token.
    @return address The 20-byte owner address.
    """
    owner: address = self._owners[token_id]
    assert owner != empty(address), "ERC721: invalid token ID"
    return owner


@external
@view
def tokenURI(token_id: uint256) -> String[512]:
    """
    @dev Returns the Uniform Resource Identifier (URI)
         for `token_id` token.
    @notice Throws if `token_id` is not a valid ERC-721 token.  
    @param token_id The 32-byte identifier of the token.
    @return String The maximum 512-byte user-readable string
            token URI of the `token_id` token.
    """
    self._require_minted(token_id)
    token_uri: String[350] = self._token_uris[token_id]

    if (len(_BASE_URI) == 0):
        return token_uri
    
    if (len(token_uri) > 0):
        return concat(_BASE_URI, token_uri)

    if (len(_BASE_URI) > 0):
        return concat(_BASE_URI, uint2str(token_id))
    else:
        return ""


@external
@payable
def approve(to: address, token_id: uint256):
    owner: address = ERC721(self).ownerOf(token_id)
    assert to != owner, "ERC721: approval to current owner"
    assert owner == msg.sender or self.isApprovedForAll[owner][msg.sender], "ERC721: approve caller is not token owner or approved for all"
    self._approve(to, token_id)


@external
@view
def getApproved(token_id: uint256) -> address:
    self._require_minted(token_id)
    return self._token_approvals[token_id]


@external
def setApprovalForAll(operator: address, approved: bool):
    self._set_approval_for_all(msg.sender, operator, approved)


@external
@payable
def transferFrom(owner: address, to: address, token_id: uint256):
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
    self._transfer(owner, to, token_id)


@external
@payable
def safeTransferFrom(owner: address, to: address, token_id: uint256, data: Bytes[1024]):
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
    self._safe_transfer(owner, to, token_id, data)


@external
@view
def totalSupply() -> uint256:
    return len(self._all_tokens)


@external
@view
def tokenByIndex(index: uint256) -> uint256:
    assert index < IERC721Enumerable(self).totalSupply(), "ERC721Enumerable: global index out of bounds"
    return self._all_tokens[index]


@external
@view
def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256:
    assert index < ERC721(self).balanceOf(owner), "ERC721Enumerable: owner index out of bounds"
    return self._owned_tokens[owner][index]


@external
def safe_mint(owner: address, uri: String[350]):
    """
    @dev TBD
    """
    assert self.is_minter[msg.sender], "AccessControl: access is denied"
    token_id: uint256 = unsafe_add(IERC721Enumerable(self).totalSupply(), 1)
    self._safe_mint(owner, token_id, b"")
    self._set_token_uri(token_id, uri)


@external
def burn(token_id: uint256):
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
    self._burn(token_id)


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
    self._check_owner()
    assert minter != empty(address), "AccessControl: minter is the zero address"
    assert minter != self.owner, "AccessControl: minter is owner address"
    self.is_minter[minter] = status
    log RoleMinterChanged(minter, status)


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
    assert block.timestamp <= deadline, "ERC721Permit: expired deadline"

    owner: address = ERC721(self).ownerOf(token_id)

    current_nonce: uint256 = self.nonces[token_id]
    self.nonces[token_id] = unsafe_add(current_nonce, 1)

    struct_hash: bytes32 = keccak256(_abi_encode(_PERMIT_TYPE_HASH, spender, token_id, current_nonce, deadline))
    hash: bytes32  = self._hash_typed_data_v4(struct_hash)

    signer: address = self._recover_vrs(hash, convert(v, uint256), convert(r, uint256), convert(s, uint256))
    assert signer == owner, "ERC721Permit: invalid signature"

    self._approve(spender, token_id)


@external
@view
def DOMAIN_SEPARATOR() -> bytes32:
    """
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    return self._domain_separator_v4()


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
    @dev Leaves the contract without an owner.
    @notice Renouncing ownership will leave the
            contract without an owner, thereby
            removing any functionality that is
            only available to the owner. Notice,
            that the `owner` is also removed from
            the list of allowed minters.

            WARNING: All other existing `minter`
            addresses will still be able to create
            new tokens. Consider removing all non-owner
            minter addresses first via `set_minter`
            before calling `renounce_ownership`.
    """
    self._check_owner()
    self.is_minter[msg.sender] = False
    self._transfer_ownership(empty(address))


@internal
@view
def _require_minted(token_id: uint256):
    """
    @dev Reverts if the `token_id` has not yet been minted.
    @param token_id The 32-byte identifier of the token.
    """
    assert self._exists(token_id), "ERC721: invalid token ID"


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
    @return The verification whether `token_id` exists
            or not.
    """
    return self._owners[token_id] != empty(address)


@internal
def _approve(to: address, token_id: uint256):
    self._token_approvals[token_id] = to
    log Approval(ERC721(self).ownerOf(token_id), to, token_id)


@internal
def _set_approval_for_all(owner: address, operator: address, approved: bool):
    assert owner != operator, "ERC721: approve to caller"
    self.isApprovedForAll[owner][operator] = approved
    log ApprovalForAll(owner, operator, approved)


@internal
def _is_approved_or_owner(spender: address, token_id: uint256) -> bool:
    owner: address = ERC721(self).ownerOf(token_id)
    return (spender == owner or self.isApprovedForAll[owner][spender] or ERC721(self).getApproved(token_id) == spender)


@internal
def _safe_mint(to: address, token_id: uint256, data: Bytes[1024]):
    self._mint(to, token_id)
    assert self._check_on_erc721_received(empty(address), to, token_id, data), "ERC721: transfer to non ERC721Receiver implementer"


@internal
def _mint(to: address, token_id: uint256):
    assert to != empty(address), "ERC721: mint to the zero address"
    assert not(self._exists(token_id)), "ERC721: token already minted"

    self._before_token_transfer(empty(address), to, token_id)

    assert not(self._exists(token_id)), "ERC721: token already minted"
    self._balances[to] = unsafe_add(self._balances[to], 1)
    self._owners[token_id] = to
    log Transfer(empty(address), to, token_id)

    self._after_token_transfer(empty(address), to, token_id)


@internal
def _safe_transfer(owner: address, to: address, token_id: uint256, data: Bytes[1024]):
    self._transfer(owner, to, token_id)


@internal
def _transfer(owner: address, to: address, token_id: uint256):
    assert ERC721(self).ownerOf(token_id) == owner, "ERC721: transfer from incorrect owner"
    assert to != empty(address), "ERC721: transfer to the zero address"
    
    self._before_token_transfer(owner, to, token_id)

    assert ERC721(self).ownerOf(token_id) == owner, "ERC721: transfer from incorrect owner"
    self._token_approvals[token_id] = empty(address)
    self._balances[owner] = unsafe_sub(self._balances[owner], 1)
    self._balances[to] = unsafe_add(self._balances[to], 1)
    self._owners[token_id] = to
    log Transfer(owner, to, token_id)

    self._after_token_transfer(owner, to, token_id)


@internal
def _set_token_uri(token_id: uint256, token_uri: String[350]):
    assert self._exists(token_id), "ERC721URIStorage: URI set of nonexistent token"
    self._token_uris[token_id] = token_uri


@internal
def _burn(token_id: uint256):
    owner: address = ERC721(self).ownerOf(token_id)

    self._before_token_transfer(owner, empty(address), token_id)

    owner = ERC721(self).ownerOf(token_id)
    self._token_approvals[token_id] = empty(address)
    self._balances[owner] = unsafe_sub(self._balances[owner], 1)
    self._owners[token_id] = empty(address)
    log Transfer(owner, empty(address), token_id)

    self._after_token_transfer(owner, empty(address), token_id)

    if (len(self._token_uris[token_id]) > 0):
        self._token_uris[token_id] = ""


@internal
def _check_on_erc721_received(owner: address, to: address, token_id: uint256, data: Bytes[1024]) -> bool:
    if (to.is_contract):
        return_value: bytes4 = IERC721Receiver(to).onERC721Received(msg.sender, owner, token_id, data)
        assert return_value == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4), "ERC721: transfer to non ERC721Receiver implementer"
        return True
    else:
        return False


@internal
def _before_token_transfer(owner: address, to: address, first_token_id: uint256):
    token_id: uint256 = first_token_id

    if (owner == empty(address)):
        self._add_token_to_all_tokens_enumeration(token_id)
    elif (owner != to):
        self._remove_token_from_owner_enumeration(owner, token_id)

    if (to == empty(address)):
        self._remove_token_from_all_tokens_enumeration(token_id)
    elif (to != owner):
        self._add_token_to_owner_enumeration(to, token_id)


@internal
def _after_token_transfer(owner: address, to: address, first_token_id: uint256):
    pass


@internal
def _add_token_to_owner_enumeration(to: address, token_id: uint256):
    length: uint256 = ERC721(self).balanceOf(to)
    self._owned_tokens[to][length] = token_id
    self._owned_tokens_index[token_id] = length


@internal
def _add_token_to_all_tokens_enumeration(token_id: uint256):
    self._all_tokens_index[token_id] = len(self._all_tokens)
    self._all_tokens.append(token_id)


@internal
def _remove_token_from_owner_enumeration(owner: address, token_id:uint256):
    last_token_index: uint256 = ERC721(self).balanceOf(owner) - 1
    token_index: uint256 = self._owned_tokens_index[token_id]

    if (token_index != last_token_index):
        last_token_id: uint256 = self._owned_tokens[owner][last_token_index]
        self._owned_tokens[owner][token_index] = last_token_id
        self._owned_tokens_index[last_token_id] = token_index
    
    self._owned_tokens_index[token_id] = 0
    self._owned_tokens[owner][last_token_index] = 0


@internal
def _remove_token_from_all_tokens_enumeration(token_id: uint256):
    last_token_index: uint256 = len(self._all_tokens) - 1
    token_index: uint256 = self._all_tokens_index[token_id]
    last_token_id: uint256  = self._all_tokens[last_token_index]

    self._all_tokens[token_index] = last_token_id
    self._all_tokens_index[last_token_id] = token_index

    self._all_tokens_index[token_id] = 0
    self._all_tokens.pop()


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
    @notice This is an `internal` function without
            access restriction.
    @param new_owner The 20-byte address of the new owner.
    """
    old_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(old_owner, new_owner)


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
