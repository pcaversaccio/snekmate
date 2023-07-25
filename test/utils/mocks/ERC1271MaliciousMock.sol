// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";

/**
 * @title ERC1271MaliciousMock
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/ERC1271WalletMock.sol.
 * @dev Allows to mock a malicious ERC-1271 implementation.
 */
contract ERC1271MaliciousMock is IERC1271 {
    /**
     * @dev Returns a malicious 4-byte magic value.
     * @return bytes4 The malicious 4-byte magic value.
     */
    function isValidSignature(
        bytes32,
        bytes memory
    ) public pure override returns (bytes4) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(
                0,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            return(0, 32)
        }
    }
}
