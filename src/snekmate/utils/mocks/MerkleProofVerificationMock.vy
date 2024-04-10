# pragma version ~=0.4.0b6
"""
@title MerkleProofVerification Module Reference Implementation
@custom:contract-name MerkleProofVerificationMock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `MerkleProofVerification` module.
# @notice Please note that the `MerkleProofVerification`
# module is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import MerkleProofVerification as mp


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
def verify(proof: DynArray[bytes32, max_value(uint8)], root: bytes32, leaf: bytes32) -> bool:
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
def multi_proof_verify(proof: DynArray[bytes32, max_value(uint8)], proof_flags: DynArray[bool, max_value(uint8)],
                       root: bytes32, leaves: DynArray[bytes32, max_value(uint8)]) -> bool:
    """
    @dev Returns `True` if it can be simultaneously proved that
         `leaves` are part of a Merkle tree defined by `root`
         and a given set of `proof_flags`.
    @notice Note that not all Merkle trees allow for multiproofs.
            See {MerkleProofVerification-_process_multi_proof} for
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
    """
    return mp._multi_proof_verify(proof, proof_flags, root, leaves)
