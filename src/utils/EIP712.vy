# @version ^0.3.4
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


_CACHED_DOMAIN_SEPARATOR: immutable(bytes32)
_CACHED_CHAIN_ID: immutable(uint256)
_CACHED_THIS: immutable(address)

_HASHED_NAME: immutable(bytes32)
_HASHED_VERSION: immutable(bytes32)
_TYPE_HASH: immutable(bytes32)


# @dev A Vyper contract cannot call directly between two external functions.
# To bypass this, we can use an interface.
interface domainSeparatorV4:
    def _domain_separator_v4() -> bytes32: view


@external
def __init__(name: String[50], version: String[20]):
    """
    @dev Initialises the domain separator and the parameter caches.
    @notice The definition of the domain separator can be found here:
            https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator.
            Since the Vyper design requires strings of fixed size,
            we arbitrarily set the maximum length for `name` to 50 bytes
            and `version` to 20 bytes.
    @param name The maximum 50-bytes user-readable string name of
           the signing domain, i.e. the name of the dApp or protocol.
    @param version The maximum 20-bytes current main version of the
           signing domain. Signatures from different versions are
           not compatible.
    """
    hashed_name: bytes32 = keccak256(convert(name, Bytes[50]))
    hashed_version: bytes32 = keccak256(convert(version, Bytes[20]))
    type_hash: bytes32 = keccak256(convert("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)", Bytes[82]))
    _HASHED_NAME = hashed_name
    _HASHED_VERSION = hashed_version
    _CACHED_CHAIN_ID = chain.id
    _CACHED_DOMAIN_SEPARATOR = self._build_domain_separator(type_hash, hashed_name, type_hash)
    _CACHED_THIS = self
    _TYPE_HASH = type_hash


@external
@view
def _domain_separator_v4() -> bytes32:
    """
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-bytes domain separator.
    """
    if (self == _CACHED_THIS and chain.id == _CACHED_CHAIN_ID):
        return _CACHED_DOMAIN_SEPARATOR
    else:
        return self._build_domain_separator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION)


@internal
@view
def _build_domain_separator(type_hash: bytes32, name_hash: bytes32, version_hash: bytes32) -> bytes32:
    """
    @dev Builds the domain separator for the current chain.
    @return bytes32 The 32-bytes domain separator.
    """
    return keccak256(concat(type_hash, name_hash, version_hash, convert(chain.id, bytes32), convert(self, bytes20)))


@external
@view
def _hash_typed_data_v4(struct_hash: bytes32) -> bytes32:
    """
    @dev Returns the hash of the fully encoded EIP-712
         message for this domain.
    @notice The definition of the hashed struct can be found here:
            https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    @param struct_hash The 32-bytes hashed struct.
    @return bytes32 The 32-bytes fully encoded EIP712
            message hash for this domain.
    """
    return self._to_typed_data_hash(domainSeparatorV4(self)._domain_separator_v4(), struct_hash)


@internal
@pure
def _to_typed_data_hash(domain_separator: bytes32, struct_hash: bytes32) -> bytes32:
    """
    @dev Sourced from {ECDSA-to_typed_data_hash}.
    @notice See {ECDSA-to_typed_data_hash} for the
            function docstring.
    """
    return keccak256(concat(b"\x19\x01", domain_separator, struct_hash))
