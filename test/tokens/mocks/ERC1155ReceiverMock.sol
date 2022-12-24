// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ERC1155ReceiverMock
 * @author jtriley.eth
 * @notice Implements necessary callbacks for ERC1155Receiver
 */
contract ERC1155ReceiverMock {
    /**
     * @notice Called when single transfer executed.
     * @return Returns selector for validation
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
     * @notice Called when single transfer executed.
     * @return Returns selector for validation
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return bytes4(
            keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
        );
    }
}
