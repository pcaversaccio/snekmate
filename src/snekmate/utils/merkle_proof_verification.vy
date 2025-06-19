# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Merkle Tree Proof Verification Functions
@custom:contract-name merkle_proof_verification
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice The Merkle tree and the corresponding proofs can be generated
        using the following JavaScript libraries:
        - https://github.com/OpenZeppelin/merkle-tree (recommended),
        - https://github.com/miguelmota/merkletreejs (deprecated).
        If you are using the (deprecated) JavaScript library `merkletreej`
        (https://github.com/miguelmota/merkletreejs), you must select
        `keccak256` as the hashing algorithm and pair sorting should
        be enabled. You should avoid using 64-byte leaf values before
        hashing or using a hash function other than `keccak256` for
        hashing leaves. The reason for this is that the concatenation
        of a sorted pair of internal nodes in the Merkle tree could be
        reinterpreted as a leaf value. OpenZeppelin's JavaScript library
        `merkle-tree` (https://github.com/OpenZeppelin/merkle-tree)
        generates Merkle trees that are safe against this attack out of
        the box. You will find a quick start guide in the `README`.
        OpenZeppelin provides some good examples of how to construct
        Merkle tree proofs correctly:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/cryptography/MerkleProof.test.js.

        Please note that this contract is written in the most agnostic
        way possible and users should adjust statically allocatable memory
        to their specific needs before deploying it:
        https://github.com/pcaversaccio/snekmate/discussions/82.

        The implementation is inspired by OpenZeppelin's implementation here:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol.
"""


# @dev Stores the 1-byte upper bound for the dynamic arrays.
_DYNARRAY_BOUND: constant(uint8) = max_value(uint8)


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@internal
@pure
def _verify(proof: DynArray[bytes32, _DYNARRAY_BOUND], root: bytes32, leaf: bytes32) -> bool:
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
    return self._process_proof(proof, leaf) == root


@internal
@pure
def _multi_proof_verify(
    proof: DynArray[bytes32, _DYNARRAY_BOUND],
    proof_flags: DynArray[bool, _DYNARRAY_BOUND],
    root: bytes32,
    leaves: DynArray[bytes32, _DYNARRAY_BOUND],
) -> bool:
    """
    @dev Returns `True` if it can be simultaneously proved that
         `leaves` are part of a Merkle tree defined by `root`
         and a given set of `proof_flags`.
    @notice Note that not all Merkle trees allow for multiproofs.
            See `_process_multi_proof` for further details.
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
                     effectively treated as a no-op in {_process_multi_proof}
                     (i.e. it simply returns `proof[0]`) and is thus
                     regarded as a valid multiproof. However, if you are
                     not validating the leaves in another part of your
                     code, you may want to consider disallowing this case.
    """
    return self._process_multi_proof(proof, proof_flags, leaves) == root


@internal
@pure
def _process_proof(proof: DynArray[bytes32, _DYNARRAY_BOUND], leaf: bytes32) -> bytes32:
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
    for proof_element: bytes32 in proof:
        computed_hash = self._hash_pair(computed_hash, proof_element)
    return computed_hash


@internal
@pure
def _process_multi_proof(
    proof: DynArray[bytes32, _DYNARRAY_BOUND],
    proof_flags: DynArray[bool, _DYNARRAY_BOUND],
    leaves: DynArray[bytes32, _DYNARRAY_BOUND],
) -> bytes32:
    """
    @dev Returns the recovered hash obtained by traversing
         a Merkle tree from `leaves` using `proof` and a
         a given set of `proof_flags`.
    @notice The reconstruction is performed by incrementally
            reconstructing all inner nodes by combining a
            leaf/inner node with either another leaf/inner node
            or a proof sibling node, depending on whether each
            `proof_flags` element is `True` or `False`.

            IMPORTANT: Note that not all Merkle trees allow for
            multiproofs. In order to use multiproofs, it is
            sufficient to ensure that:
            1) the Merkle tree is complete (but not necessarily
               perfect),
            2) the `leaves` to be proved are in the reverse order
               in which they are in the Merkle tree (i.e. from right
               to left, starting with the deepest layer and moving
               on to the next layer). For the definition of the
               generalised Merkle tree index, please visit:
               https://github.com/ethereum/consensus-specs/blob/dev/ssz/merkle-proofs.md#generalized-merkle-tree-index.
    @param proof The 32-byte array containing sibling hashes
           on the branches from `leaves` to the `root` of the
           Merkle tree.
    @param proof_flags The Boolean array of flags indicating
           whether another value from the "main queue" (merging
           branches) or an element from the `proof` array is used
           to calculate the next hash.
    @param leaves The 32-byte array containing the leaf hashes.
    @return bytes32 The 32-byte recovered hash by using `leaves`
            and `proof` with a given set of `proof_flags`.
    @custom:security It's crucial to recognise that the condition where
                     `((len(proof) == 1) and (len(leaves) == 0))` (i.e.
                     the empty set), is effectively treated as a no-op
                     and thus is considered a valid multiproof, returning
                     `proof[0]`. However, if you are not validating the
                     leaves in another part of your code, you may want to
                     consider disallowing this case.
    """
    leaves_length: uint256 = len(leaves)
    total_hashes: uint256 = len(proof_flags)

    # Checks the validity of the proof. We do not check for an
    # overflow (nor underflow) as `leaves_length`, `proof`, and
    # `total_hashes` are bounded by the value `max_value(uint8)`
    # and therefore cannot overflow the `uint256` type when they
    # are added together or incremented by `1`.
    assert unsafe_add(leaves_length, len(proof)) == unsafe_add(
        total_hashes, 1
    ), "merkle_proof_verification: invalid multiproof"

    hashes: DynArray[bytes32, _DYNARRAY_BOUND] = []
    leaf_pos: uint256 = empty(uint256)
    hash_pos: uint256 = empty(uint256)
    proof_pos: uint256 = empty(uint256)
    a: bytes32 = empty(bytes32)
    b: bytes32 = empty(bytes32)

    # At each step, the next hash is calculated from two values:
    # - a value from the "main queue". If not all leaves have been used,
    #   the next leaf is picked up, otherwise the next hash.
    # - depending on the flag, either another value from the "main queue"
    #   (merging branches) or an element from the `proof` array.
    for flag: bool in proof_flags:
        if leaf_pos < leaves_length:
            a = leaves[leaf_pos]
            leaf_pos = unsafe_add(leaf_pos, 1)
        else:
            a = hashes[hash_pos]
            hash_pos = unsafe_add(hash_pos, 1)
        if flag:
            if leaf_pos < leaves_length:
                b = leaves[leaf_pos]
                leaf_pos = unsafe_add(leaf_pos, 1)
            else:
                b = hashes[hash_pos]
                hash_pos = unsafe_add(hash_pos, 1)
        else:
            b = proof[proof_pos]
            proof_pos = unsafe_add(proof_pos, 1)
        hashes.append(self._hash_pair(a, b))

    if total_hashes != empty(uint256):
        # Vyper, unlike Python, does not support negative
        # indexing and would revert in such a case. In any event,
        # the array index cannot become negative here by design.
        return hashes[unsafe_sub(total_hashes, 1)]
    elif leaves_length != empty(uint256):
        return leaves[empty(uint256)]

    return proof[empty(uint256)]


@internal
@pure
def _hash_pair(a: bytes32, b: bytes32) -> bytes32:
    """
    @dev Returns the `keccak256` hash of `a` and `b` after concatenation.
    @notice The concatenation pattern is determined by the sorting assumption
            of hashing pairs.
    @param a The first 32-byte hash value to be concatenated and hashed.
    @param b The second 32-byte hash value to be concatenated and hashed.
    @return bytes32 The 32-byte `keccak256` hash of `a` and `b`.
    """
    if convert(a, uint256) < convert(b, uint256):
        return keccak256(concat(a, b))

    return keccak256(concat(b, a))
