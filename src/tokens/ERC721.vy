# pragma version ^0.3.10
"""
@title Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation
@custom:contract-name ERC721
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


# @dev We import and implement the `ERC165` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import and implement the `ERC721` interface,
# which is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC721
implements: ERC721


# @dev We import and implement the `IERC721Metadata`
# interface, which is written using standard Vyper
# syntax.
import interfaces.IERC721Metadata as IERC721Metadata
implements: IERC721Metadata


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


# @dev We import and implement the `IERC4906` interface,
# which is written using standard Vyper syntax.
import interfaces.IERC4906 as IERC4906
implements: IERC4906


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ..utils.interfaces.IERC5267 import IERC5267
implements: IERC5267


# @dev We import the `IERC721Receiver` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC721Receiver as IERC721Receiver


# @dev Stores the ERC-165 interface identifier for each
# imported interface. The ERC-165 interface identifier
# is defined as the XOR of all function selectors in the
# interface.
_SUPPORTED_INTERFACES: constant(bytes4[6]) = [
    0x01FFC9A7, # The ERC-165 identifier for ERC-165.
    0x80AC58CD, # The ERC-165 identifier for ERC-721.
    0x5B5E139F, # The ERC-165 identifier for the ERC-721 metadata extension.
    0x780E9D63, # The ERC-165 identifier for the ERC-721 enumeration extension.
    0x589C5CE2, # The ERC-165 identifier for ERC-4494.
    0x49064906, # The ERC-165 identifier for ERC-4906.
]


# @dev Constant used as part of the ECDSA recovery function.
_MALLEABILITY_THRESHOLD: constant(bytes32) = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0


# @dev The 32-byte type hash for the EIP-712 domain separator.
_TYPE_HASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")


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
_BASE_URI: immutable(String[80])


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


# @dev Emitted when the metadata of a token is
# changed.
event MetadataUpdate:
    token_id: uint256


# @dev Emitted when the metadata of a range of
# tokens is changed.
event BatchMetadataUpdate:
    from_token_id: uint256
    token_id: uint256


# @dev May be emitted to signal that the domain could
# have changed.
event EIP712DomainChanged:
    pass


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
def __init__(name_: String[25], symbol_: String[5], base_uri_: String[80], name_eip712_: String[50], version_eip712_: String[20]):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @notice The `owner` role will be assigned to
            the `msg.sender`.
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

    self._transfer_ownership(msg.sender)
    self.is_minter[msg.sender] = True
    log RoleMinterChanged(msg.sender, True)

    _NAME = name_eip712_
    _VERSION = version_eip712_
    _HASHED_NAME = keccak256(name_eip712_)
    _HASHED_VERSION = keccak256(version_eip712_)
    _CACHED_DOMAIN_SEPARATOR = self._build_domain_separator()
    _CACHED_CHAIN_ID = chain.id
    _CACHED_SELF = self


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
    assert to != owner, "ERC721: approval to current owner"
    assert msg.sender == owner or self.isApprovedForAll[owner][msg.sender], "ERC721: approve caller is not token owner or approved for all"
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
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
    self._transfer(owner, to, token_id)


@external
@payable
def safeTransferFrom(owner: address, to: address, token_id: uint256, data: Bytes[1_024]=b""):
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
            https://github.com/vyperlang/vyper/issues/903.

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
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
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
    if (base_uri_length == empty(uint256)):
        return token_uri

    # If both are set, concatenate the base URI
    # and token URI.
    if (len(token_uri) != empty(uint256)):
        return concat(_BASE_URI, token_uri)

    # If there is no token URI but a base URI,
    # concatenate the base URI and token ID.
    if (base_uri_length != empty(uint256)):
        return concat(_BASE_URI, uint2str(token_id))
    else:
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
           than `totalSupply()`).
    @return uint256 The 32-byte token ID at index
            `index`.
    """
    assert index < self._total_supply(), "ERC721Enumerable: global index out of bounds"
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
    assert index < self._balance_of(owner), "ERC721Enumerable: owner index out of bounds"
    return self._owned_tokens[owner][index]


@external
def burn(token_id: uint256):
    """
    @dev Burns the `token_id` token.
    @notice Note that the caller must own `token_id`
            or be an approved operator.
    @param token_id The 32-byte identifier of the token.
    """
    assert self._is_approved_or_owner(msg.sender, token_id), "ERC721: caller is not token owner or approved"
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
    assert self.is_minter[msg.sender], "AccessControl: access is denied"
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
    self._check_owner()
    assert minter != empty(address), "AccessControl: minter is the zero address"
    # We ensured in the previous step `self._check_owner()`
    # that `msg.sender` is the `owner`.
    assert minter != msg.sender, "AccessControl: minter is owner address"
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

    owner: address = self._owner_of(token_id)
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
    self._check_owner()
    assert new_owner != empty(address), "Ownable: new owner is the zero address"

    self.is_minter[msg.sender] = False
    log RoleMinterChanged(msg.sender, False)

    self._transfer_ownership(new_owner)
    self.is_minter[new_owner] = True
    log RoleMinterChanged(new_owner, True)


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
    self._check_owner()
    self.is_minter[msg.sender] = False
    log RoleMinterChanged(msg.sender, False)
    self._transfer_ownership(empty(address))


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
    assert owner != empty(address), "ERC721: the zero address is not a valid owner"
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
    assert owner != empty(address), "ERC721: invalid token ID"
    return owner


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
    log Approval(self._owner_of(token_id), to, token_id)


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
    assert owner != operator, "ERC721: approve to caller"
    self.isApprovedForAll[owner][operator] = approved
    log ApprovalForAll(owner, operator, approved)


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
    return (spender == owner or self.isApprovedForAll[owner][spender] or self._get_approved(token_id) == spender)


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
    assert self._check_on_erc721_received(empty(address), owner, token_id, data), "ERC721: transfer to non-ERC721Receiver implementer"


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
    assert owner != empty(address), "ERC721: mint to the zero address"
    assert not(self._exists(token_id)), "ERC721: token already minted"

    self._before_token_transfer(empty(address), owner, token_id)
    # Checks that the `token_id` was not minted by the
    # `_before_token_transfer` hook.
    assert not(self._exists(token_id)), "ERC721: token already minted"

    # Theoretically, the following line could overflow
    # if all 2**256 token IDs were minted to the same owner.
    # However, since we have bounded the dynamic array
    # `_all_tokens` by the maximum value of `uint64`,
    # this is no longer even theoretically possible.
    self._balances[owner] = unsafe_add(self._balances[owner], 1)
    self._owners[token_id] = owner
    log Transfer(empty(address), owner, token_id)

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
    assert self._check_on_erc721_received(owner, to, token_id, data), "ERC721: transfer to non-ERC721Receiver implementer"


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
    assert self._owner_of(token_id) == owner, "ERC721: transfer from incorrect owner"
    assert to != empty(address), "ERC721: transfer to the zero address"
    
    self._before_token_transfer(owner, to, token_id)
    # Checks that the `token_id` was not transferred by the
    # `_before_token_transfer` hook.
    assert self._owner_of(token_id) == owner, "ERC721: transfer from incorrect owner"
    
    self._token_approvals[token_id] = empty(address)
    # See comment why an overflow is not possible in the
    # following two lines above at `_mint`.
    self._balances[owner] = unsafe_sub(self._balances[owner], 1)
    self._balances[to] = unsafe_add(self._balances[to], 1)
    self._owners[token_id] = to
    log Transfer(owner, to, token_id)

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
    assert self._exists(token_id), "ERC721URIStorage: URI set of nonexistent token"
    self._token_uris[token_id] = token_uri
    log MetadataUpdate(token_id)


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
    # have to be burnt/transferred than the owner originally
    # received through minting and transfer.
    self._balances[owner] = unsafe_sub(self._balances[owner], 1)
    self._owners[token_id] = empty(address)
    log Transfer(owner, empty(address), token_id)

    self._after_token_transfer(owner, empty(address), token_id)

    # Checks whether a token-specific URI has been set for the token
    # and deletes the token URI from the storage mapping.
    if (len(self._token_uris[token_id]) != empty(uint256)):
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
    if (to.is_contract):
        return_value: bytes4 = IERC721Receiver(to).onERC721Received(msg.sender, owner, token_id, data)
        assert return_value == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4), "ERC721: transfer to non-ERC721Receiver implementer"
        return True
    # EOA case.
    else:
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
    if (owner == empty(address)):
        self._add_token_to_all_tokens_enumeration(token_id)
    elif (owner != to):
        self._remove_token_from_owner_enumeration(owner, token_id)

    if (to == empty(address)):
        self._remove_token_from_all_tokens_enumeration(token_id)
    elif (to != owner):
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
def _remove_token_from_owner_enumeration(owner: address, token_id:uint256):
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
    if (token_index != last_token_index):
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
    # minted token is burnt) that we still do the
    # swap here to avoid the gas cost of adding
    # an 'if' statement (like in `_remove_token_from_owner_enumeration`).
    last_token_id: uint256  = self._all_tokens[last_token_index]

    # Moves the last token to the slot of the to-delete token.
    self._all_tokens[token_index] = last_token_id
    # Updates the moved token's index.
    self._all_tokens_index[last_token_id] = token_index

    # This also deletes the contents at the
    # last position of the array.
    self._all_tokens_index[token_id] = empty(uint256)
    self._all_tokens.pop()


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
