# @version ^0.3.7
"""
@title EIP-712 Domain Separator
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions are part of EIP-712: https://eips.ethereum.org/EIPS/eip-712.
        These functions implement the version of encoding known
        as "v4" as implemented by the JSON-RPC method:
        https://docs.metamask.io/guide/signing-data.html#sign-typed-data-v4.
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/draft-EIP712.sol.
"""


# @dev Caches the domain separator as an `immutable`
# value, but also stores the corresponding chain id
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


@external
@payable
def __init__(name_: String[50], version_: String[20]):
    """
    @dev Initialises the domain separator and the parameter caches.
         To omit the opcodes for checking the `msg.value` in the
         creation-time EVM bytecode, the constructor is declared as
         `payable`.
    @notice The definition of the domain separator can be found here:
            https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator.
            Since the Vyper design requires strings of fixed size,
            we arbitrarily set the maximum length for `name` to 50
            characters and `version` to 20 characters.
    @param name_ The maximum 50-character user-readable string name
           of the signing domain, i.e. the name of the dApp or protocol.
    @param version_ The maximum 20-character current main version of
           the signing domain. Signatures from different versions are
           not compatible.
    """
    hashed_name: bytes32 = keccak256(convert(name_, Bytes[50]))
    hashed_version: bytes32 = keccak256(convert(version_, Bytes[20]))
    type_hash: bytes32 = keccak256(convert("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)", Bytes[82]))
    _HASHED_NAME = hashed_name
    _HASHED_VERSION = hashed_version
    _TYPE_HASH = type_hash
    _CACHED_CHAIN_ID = chain.id
    _CACHED_SELF = self
    _CACHED_DOMAIN_SEPARATOR = self._build_domain_separator(type_hash, hashed_name, hashed_version)


@external
@view
def domain_separator_v4() -> bytes32:
    """
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    return self._domain_separator_v4()


@external
@view
def hash_typed_data_v4(struct_hash: bytes32) -> bytes32:
    """
    @dev Returns the hash of the fully encoded EIP-712
         message for this domain.
    @notice The definition of the hashed struct can be found here:
            https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    @param struct_hash The 32-byte hashed struct.
    @return bytes32 The 32-byte fully encoded EIP712
            message hash for this domain.
    """
    return self._to_typed_data_hash(self._domain_separator_v4(), struct_hash)


@internal
@view
def _domain_separator_v4() -> bytes32:
    """
    @dev An `internal` helper function that returns the domain separator
         for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    if (self == _CACHED_SELF and chain.id == _CACHED_CHAIN_ID):
        return _CACHED_DOMAIN_SEPARATOR
    else:
        return self._build_domain_separator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION)


@internal
@view
def _build_domain_separator(type_hash: bytes32, name_hash: bytes32, version_hash: bytes32) -> bytes32:
    """
    @dev Builds the domain separator for the current chain.
    @param type_hash The 32-byte hashed type.
    @param name_hash The 32-byte hashed name.
    @param version_hash The 32-byte hashed version.
    @return bytes32 The 32-byte domain separator.
    """
    return keccak256(_abi_encode(type_hash, name_hash, version_hash, chain.id, self))


@internal
@pure
def _to_typed_data_hash(domain_separator: bytes32, struct_hash: bytes32) -> bytes32:
    """
    @dev Sourced from {ECDSA-to_typed_data_hash}.
    @notice See {ECDSA-to_typed_data_hash} for the
            function docstring.
    """
    return keccak256(concat(b"\x19\x01", domain_separator, struct_hash))
