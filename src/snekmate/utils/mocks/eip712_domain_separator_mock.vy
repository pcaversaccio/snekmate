# pragma version ~=0.4.1b3
"""
@title `eip712_domain_separator` Module Reference Implementation
@custom:contract-name eip712_domain_separator_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import and implement the `IERC5267` interface,
# which is written using standard Vyper syntax.
from ..interfaces import IERC5267
implements: IERC5267


# @dev We import and initialise the `eip712_domain_separator` module.
from .. import eip712_domain_separator as ed
initializes: ed


# @dev We export (i.e. the runtime bytecode exposes these
# functions externally, allowing them to be called using
# the ABI encoding specification) the `external` function
# `eip712Domain` from the `eip712_domain_separator` module.
# @notice Please note that you must always also export (if
# required by the contract logic) `public` declared `constant`,
# `immutable`, and state variables, for which Vyper automatically
# generates an `external` getter function for the variable.
exports: ed.eip712Domain


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
    ed.__init__(name_, version_)


@external
@view
def domain_separator_v4() -> bytes32:
    """
    @dev Returns the domain separator for the current chain.
    @return bytes32 The 32-byte domain separator.
    """
    return ed._domain_separator_v4()


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
    return ed._hash_typed_data_v4(struct_hash)
