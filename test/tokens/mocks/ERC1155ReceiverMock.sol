// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ShouldRevert();

contract ERC1155ReceiverMock {
    bool internal _shouldRevert;

    function toggleShouldRevert() public {
        _shouldRevert = !_shouldRevert;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        view
        returns (bytes4)
    {
        if (_shouldRevert) revert ShouldRevert();
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view returns (bytes4) {
        if (_shouldRevert) revert ShouldRevert();
        return bytes4(
            keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
        );
    }
}
