# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `merkle_proof_verification` Module Reference Implementation
@custom:contract-name merkle_proof_verification_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `merkle_proof_verification` module.
# @notice Please note that the `merkle_proof_verification`
# module is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import merkle_proof_verification as mp


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@external
@pure
def verify(proof: DynArray[bytes32, mp._DYNARRAY_BOUND], root: bytes32, leaf: bytes32) -> bool:
    """
    @dev Returns `True` if it can be proved that a `leaf` is
         part of a Merkle tree defined by `root`.
    @notice Each pair of leaves and each pair of pre-images
            are assumed to be sorted.
    @param proof The 32-byte array containing sibling hashes
           on the branch from the `leaf` to the `root` of the
           Merkle tree.
    @param root The 32-byte Merkle root hash.
    @param leaf The 32-byte leaf hash.
    @return bool The verification whether `leaf` is part of
            a Merkle tree defined by `root`.
    """
    return mp._verify(proof, root, leaf)


@external
@pure
def multi_proof_verify(
    proof: DynArray[bytes32, mp._DYNARRAY_BOUND],
    proof_flags: DynArray[bool, mp._DYNARRAY_BOUND],
    root: bytes32,
    leaves: DynArray[bytes32, mp._DYNARRAY_BOUND],
) -> bool:
    """
    @dev Returns `True` if it can be simultaneously proved that
         `leaves` are part of a Merkle tree defined by `root`
         and a given set of `proof_flags`.
    @notice Note that not all Merkle trees allow for multiproofs.
            See {merkle_proof_verification-_process_multi_proof} for
            further details.
    @param proof The 32-byte array containing sibling hashes
           on the branches from `leaves` to the `root` of the
           Merkle tree.
    @param proof_flags The Boolean array of flags indicating
           whether another value from the "main queue" (merging
           branches) or an element from the `proof` array is used
           to calculate the next hash.
    @param root The 32-byte Merkle root hash.
    @param leaves The 32-byte array containing the leaf hashes.
    @return bool The verification whether `leaves` are simultaneously
            part of a Merkle tree defined by `root`.
    @custom:security It's crucial to recognise that the condition where
                     `((root == proof[0]) and (len(leaves) == 0))` is
                     effectively treated as a no-op in {mp-_process_multi_proof}
                     (i.e. it simply returns `proof[0]`) and is thus
                     regarded as a valid multiproof. However, if you are
                     not validating the leaves in another part of your
                     code, you may want to consider disallowing this case.
    """
    return mp._multi_proof_verify(proof, proof_flags, root, leaves)
