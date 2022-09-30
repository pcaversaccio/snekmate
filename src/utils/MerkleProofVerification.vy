# @version ^0.3.7
"""
@title Merkle Tree Proof Verification Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice The proofs can be generated using the JavaScript library:
        https://github.com/miguelmota/merkletreejs. You must select
        `keccak256` as the hashing algorithm and pair sorting should
        be enabled. You should avoid using 64-byte leaf values before
        hashing or using a hash function other than `keccak256` for
        hashing leaves. The reason for this is that the concatenation
        of a sorted pair of internal nodes in the Merkle tree could be
        reinterpreted as a leaf value. OpenZeppelin provides some good
        examples of how to construct Merkle tree proofs correctly:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/cryptography/MerkleProof.test.js.
        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol.
"""


@external
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value` in the
         creation-time EVM bytecode, the constructor is declared as `payable`.
    """
    pass


@external
@pure
def verify(proof: DynArray[bytes32, max_value(uint16)], root: bytes32, leaf: bytes32) -> bool:
    """
    @dev Returns true if it can be proved that a `leaf` is
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
    return self._process_proof(proof, leaf) == root


@internal
@pure
def _process_proof(proof: DynArray[bytes32, max_value(uint16)], leaf: bytes32) -> bytes32:
    """
    @dev Returns the recovered hash obtained by traversing
         a Merkle tree from `leaf` using `proof`.
    @notice Each pair of leaves and each pair of pre-images
            are assumed to be sorted.
    @param proof The 32-byte array containing sibling hashes
           on the branch from the `leaf` to the `root` of the
           Merkle tree.
    @param leaf The 32-byte leaf hash.
    @return bytes32 The 32-byte recovered hash by using `leaf`
            and `proof`.
    """
    computed_hash: bytes32 = leaf
    for i in proof:
        computed_hash = self._hash_pair(computed_hash, i)
    return computed_hash


@internal
@pure
def _hash_pair(a: bytes32, b: bytes32) -> bytes32:
    """
    @dev Returns the keccak256 hash of `a` and `b` after concatenation.
    @notice The concatenation pattern is determined by the sorting assumption
            of hashing pairs.
    @param a The first 32-byte hash value to be concatenated and hashed.
    @param b The second 32-byte hash value to be concatenated and hashed.
    @return bytes32 The 32-byte keccak256 hash of `a` and `b`.
    """
    if (convert(a, uint256) < convert(b, uint256)):
        return keccak256(concat(a, b))
    else:
        return keccak256(concat(b, a))
