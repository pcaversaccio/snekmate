// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ERC1155ReceiverMock
 * @author jtriley.eth
 * @notice Implements necessary callbacks for ERC1155Receiver
 */
contract ERC1155ReceiverMock {
    event Received(
        address indexed operator,
        address indexed from,
        uint256 id,
        uint256 amount,
        bytes data
    );

    event BatchReceived(
        address indexed operator,
        address indexed from,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    /**
     * @notice Called when single transfer executed.
     * @return Returns selector for validation
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        emit Received(operator, from, id, amount, data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
     * @notice Called when single transfer executed.
     * @return Returns selector for validation
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4) {
        emit BatchReceived(operator, from, ids, amounts, data);
        return bytes4(
            keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
        );
    }
}
