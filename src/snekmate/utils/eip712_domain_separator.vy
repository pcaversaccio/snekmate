# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title EIP-712 Domain Separator
@custom:contract-name eip712_domain_separator
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions are part of EIP-712: https://eips.ethereum.org/EIPS/eip-712.
        These functions implement the version of encoding known
        as "v4" as implemented by the JSON-RPC method:
        https://docs.metamask.io/guide/signing-data.html#sign-typed-data-v4.
        In addition, this contract also implements EIP-5267:
        https://eips.ethereum.org/EIPS/eip-5267.
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol.
"""


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from .interfaces import IERC5267
implements: IERC5267


# @dev We import the `message_hash_utils` module.
# @notice Please note that the `message_hash_utils`
# module is stateless and therefore does not require
# the `uses` keyword for usage.
from . import message_hash_utils


# @dev The 32-byte type hash for the EIP-712 domain separator.
_TYPE_HASH: constant(bytes32) = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
)


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


@deploy
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
    _NAME = name_
    _VERSION = version_
    _HASHED_NAME = keccak256(name_)
    _HASHED_VERSION = keccak256(version_)
    _CACHED_DOMAIN_SEPARATOR = self._build_domain_separator()
    _CACHED_CHAIN_ID = chain.id
    _CACHED_SELF = self


@external
@view
def eip712Domain() -> (bytes1, String[50], String[20], uint256, address, bytes32, DynArray[uint256, 32]):
    """
    @dev Returns the fields and values that describe the domain
         separator used by this contract for EIP-712 signatures.
    @notice The bits in the 1-byte bit map are read from the least
            significant to the most significant, and fields are indexed
            in the order that is specified by EIP-712, identical to the
            order in which they are listed in the function type.
    @return bytes1 The 1-byte bit map where bit `i` is set to `1`
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
    # Note that `0x0f` equals `01111`.
    return (0x0f, _NAME, _VERSION, chain.id, self, empty(bytes32), empty(DynArray[uint256, 32]))


@internal
@view
def _domain_separator_v4() -> bytes32:
    """
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    if self == _CACHED_SELF and chain.id == _CACHED_CHAIN_ID:
        return _CACHED_DOMAIN_SEPARATOR

    return self._build_domain_separator()


@internal
@view
def _build_domain_separator() -> bytes32:
    """
    @dev Builds the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    return keccak256(abi_encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, chain.id, self))


@internal
@view
def _hash_typed_data_v4(struct_hash: bytes32) -> bytes32:
    """
    @dev Returns the hash of the fully encoded EIP-712
         message for this domain.
    @notice The definition of the hashed struct can be found here:
            https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    @param struct_hash The 32-byte hashed struct.
    @return bytes32 The 32-byte fully encoded EIP712
            message hash for this domain.
    """
    return message_hash_utils._to_typed_data_hash(self._domain_separator_v4(), struct_hash)
