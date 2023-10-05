# pragma version ^0.3.10
"""
@title EIP-5267 Interface Definition
@custom:contract-name IERC5267
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The ERC-5267 standard complements the EIP-712 standard
        by standardising how contracts should publish the fields
        and values that describe their domain. This enables
        applications to retrieve this description and generate
        appropriate domain separators in a general way, and thus
        integrate EIP-712 signatures securely and scalably. For
        more details, please refer to:
        https://eips.ethereum.org/EIPS/eip-5267.

        Note that Vyper interfaces that implement functions
        with return values that require an upper bound (e.g.
        `Bytes`, `DynArray`, or `String`), the upper bound
        defined in the interface represents the lower bound
        of the implementation:
        https://github.com/vyperlang/vyper/pull/3205.

        On how to use interfaces in Vyper, please visit:
        https://vyper.readthedocs.io/en/latest/interfaces.html#interfaces.
"""


# @dev May be emitted to signal that the domain could
# have changed.
event EIP712DomainChanged:
    pass


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
    return (empty(bytes1), empty(String[50]), empty(String[20]), empty(uint256), empty(address), empty(bytes32), empty(DynArray[uint256, 128]))
