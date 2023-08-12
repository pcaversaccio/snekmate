// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC165} from "openzeppelin/utils/introspection/ERC165.sol";
import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title ERC1155ReceiverMock
 * @author jtriley.eth
 * @custom:coauthor pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/token/ERC1155ReceiverMock.sol.
 * @notice Allows to test receiving ERC-1155 tokens as a smart contract.
 */
contract ERC1155ReceiverMock is ERC165, IERC1155Receiver {
    bytes4 private recRetval;
    bool private recReverts;
    bytes4 private batRetval;
    bool private batReverts;

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

    constructor(
        bytes4 recRetval_,
        bool recReverts_,
        bytes4 batRetval_,
        bool batReverts_
    ) {
        recRetval = recRetval_;
        recReverts = recReverts_;
        batRetval = batRetval_;
        batReverts = batReverts_;
    }

    /**
     * @dev Handles the receipt of a single ERC-1155 token type.
     * This function is called at the end of a `safeTransferFrom`
     * after the balance has been updated.
     * @param operator The 20-byte address which called the `safeTransferFrom`
     * function.
     * @param from The 20-byte address which previously owned the token.
     * @param id The 32-byte identifier of the token.
     * @param amount The 32-byte token amount that is being transferred.
     * @param data The additional data with no specified format that is sent
     * to this smart contract.
     * @return bytes4 The 4-byte return identifier.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external returns (bytes4) {
        // solhint-disable-next-line reason-string, custom-errors
        require(!recReverts, "ERC1155ReceiverMock: reverting on receive");
        emit Received(operator, from, id, amount, data);
        return recRetval;
    }

    /**
     * @dev Handles the receipt of multiple ERC-1155 token types.
     * This function is called at the end of a `safeBatchTransferFrom`
     * after the balances have been updated.
     * @param operator The 20-byte address which called the `safeBatchTransferFrom`
     * function.
     * @param from The 20-byte address which previously owned the tokens.
     * @param ids The 32-byte array of token identifiers.
     * @param amounts The 32-byte array of token amounts that are being transferred.
     * @param data The additional data with no specified format that is sent
     * to this smart contract.
     * @return bytes4 The 4-byte return identifier.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external returns (bytes4) {
        // solhint-disable-next-line reason-string, custom-errors
        require(!batReverts, "ERC1155ReceiverMock: reverting on batch receive");
        emit BatchReceived(operator, from, ids, amounts, data);
        return batRetval;
    }
}
