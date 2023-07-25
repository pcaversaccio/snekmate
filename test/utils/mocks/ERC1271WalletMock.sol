// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

/**
 * @title ERC1271WalletMock
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/ERC1271WalletMock.sol.
 * @dev Allows to mock a correct ERC-1271 implementation.
 */
contract ERC1271WalletMock is Ownable, IERC1271 {
    constructor(address originalOwner_) Ownable(originalOwner_) {}

    /**
     * @dev Returns the 4-byte magic value `0x1626ba7e` if the verification passes.
     * @param hash The 32-byte message digest that was signed.
     * @param signature The secp256k1 64/65-byte signature of `hash`.
     * @return bytes4 The 4-byte magic value.
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) public view override returns (bytes4) {
        return
            ECDSA.recover(hash, signature) == owner()
                ? this.isValidSignature.selector
                : bytes4(0);
    }
}
