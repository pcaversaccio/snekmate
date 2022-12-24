// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ERC1155InvalidReceiverMock
 * @author jtriley.eth
 * @notice Implements invalid responses from an `ERC1155Receiver`.
 * @dev param names are ommitted to avoid unused variable warnings.
 */
contract ERC1155InvalidReceiverMock {
    error Throw(address emitter);

    bool internal immutable shouldThrow;

    constructor(bool _shouldThrow) {
        shouldThrow = _shouldThrow;
    }

    /**
     * @dev Conditionally reverts OR returns an invalid value.
     * @return Invalid bytes4 data.
     */
    function onERC1155Received(address,address,uint256,uint256,bytes memory)
        external 
        view
        returns (bytes4)
    {
        if (shouldThrow) revert Throw(address(this));

        return 0x00112233;
    }

    /**
     * @dev Conditionally reverts OR returns an invalid value.
     * @return Invalid bytes4 data.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external view returns (bytes4) {
        if (shouldThrow) revert Throw(address(this));

        return 0x00112233;
    }
}
