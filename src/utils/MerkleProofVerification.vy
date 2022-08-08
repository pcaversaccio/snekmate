# @version ^0.3.6
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
@pure
def verify(proof: DynArray[bytes32, max_value(uint128)], root: bytes32, leaf: bytes32) -> bool:
    """
    @dev TBD
    @param proof TBD
    @param root TBD
    @param leaf TBD
    @return bool TBD
    """
    return self._process_proof(proof, leaf) == root


@internal
@pure
def _process_proof(proof: DynArray[bytes32, max_value(uint128)], leaf: bytes32) -> bytes32:
    """
    @dev TBD
    @param proof TBD
    @param leaf TBD
    @return bytes32 TBD
    """
    computed_hash: bytes32 = leaf
    for i in proof:
        computed_hash = self._hash_pair(computed_hash, i)
    return computed_hash


@internal
@pure
def _hash_pair(a: bytes32, b: bytes32) -> bytes32:
    """
    @dev TBD
    @param a TBD
    @param b TBD
    @return bytes32 TBD
    """
    if (convert(a, uint256) < convert(b, uint256)):
        return keccak256(concat(a, b))
    else:
        return keccak256(concat(b, a))
