// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721Receiver} from "openzeppelin/token/ERC721/IERC721Receiver.sol";

/**
 * @title ERC721ReceiverMock
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/ERC721ReceiverMock.sol.
 * @dev Allows to test receiving ERC-721 tokens as a smart contract.
 */
contract ERC721ReceiverMock is IERC721Receiver {
    bytes4 private immutable _retval;

    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }
    Error private immutable _error;

    event Received(address operator, address from, uint256 tokenId, bytes data);

    constructor(bytes4 retval, Error error) {
        _retval = retval;
        _error = error;
    }

    /**
     * @dev The ERC-721 smart contract calls this function on the
     * recipient after a safe transfer.
     * @param operator The 20-byte operator address.
     * @param from The 20-byte owner address.
     * @param tokenId The 32-byte identifier of the token.
     * @param data The additional data with no specified format that is sent
     * to this smart contract.
     * @return bytes4 The 4-byte return identifier.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        if (_error == Error.RevertWithMessage) {
            revert("ERC721ReceiverMock: reverting");
        } else if (_error == Error.RevertWithoutMessage) {
            // solhint-disable-next-line reason-string
            revert();
        } else if (_error == Error.Panic) {
            uint256 a = uint256(0) / uint256(0);
            a;
        }
        emit Received(operator, from, tokenId, data);
        return _retval;
    }
}
