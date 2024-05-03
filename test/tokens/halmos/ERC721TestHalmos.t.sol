// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

import {IERC721Extended} from "../interfaces/IERC721Extended.sol";

// /**
//  * @dev Sets the timeout (in milliseconds) for solving assertion
//  * violation conditions; `0` means no timeout.
//  * @custom:halmos --solver-timeout-assertion 0
//  */
contract ERC721TestHalmos is Test, SymTest {
    string private constant _NAME = "MyNFT";
    string private constant _SYMBOL = "WAGMI";
    string private constant _BASE_URI = "https://www.wagmi.xyz/";
    string private constant _NAME_EIP712 = "MyNFT";
    string private constant _VERSION_EIP712 = "1";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IERC721 private erc721;
    address private token;
    address[] private holders;
    uint256[] private tokenIds;

    // /**
    //  * @dev Sets timeout (in milliseconds) for solving branching
    //  * conditions; `0` means no timeout.
    //  * @custom:halmos --solver-timeout-branching 1000
    //  */
    function setUp() public {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _BASE_URI,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        /**
         * @dev Halmos does not currently work with the latest Vyper jump-table-based
         * dispatchers: https://github.com/a16z/halmos/issues/253. For Halmos-based tests,
         * we therefore disable the optimiser.
         */
        erc721 = IERC721(
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "ERC721Mock",
                args,
                "shanghai",
                "none"
            )
        );

        address deployer = address(vyperDeployer);
        token = address(erc721);
        holders = new address[](3);
        holders[0] = address(0x1337);
        holders[1] = address(0x31337);
        holders[2] = address(0xbA5eD);

        tokenIds = new uint256[](5);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 3;
        tokenIds[4] = 4;

        vm.startPrank(deployer);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721Extended(token)._customMint(deployer, i);
        }
        erc721.transferFrom(deployer, holders[0], tokenIds[0]);
        erc721.transferFrom(deployer, holders[0], tokenIds[1]);
        erc721.transferFrom(deployer, holders[1], tokenIds[2]);
        erc721.transferFrom(deployer, holders[2], tokenIds[3]);
        vm.stopPrank();

        vm.startPrank(holders[0]);
        erc721.approve(holders[2], tokenIds[0]);
        vm.stopPrank();

        vm.startPrank(holders[1]);
        erc721.setApprovalForAll(holders[2], true);
        vm.stopPrank();
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/a16z/halmos/blob/main/examples/tokens/ERC721/test/ERC721Test.sol.
     */
    function testHalmosAssertNoBackdoor(
        bytes4 selector,
        address caller,
        address other
    ) public {
        vm.assume(caller != other);
        for (uint256 i = 0; i < holders.length; i++) {
            vm.assume(!erc721.isApprovedForAll(holders[i], caller));
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.assume(erc721.getApproved(tokenIds[i]) != caller);
        }

        uint256 oldBalanceCaller = erc721.balanceOf(caller);
        uint256 oldBalanceOther = erc721.balanceOf(other);

        vm.startPrank(caller);
        bool success;
        if (
            selector ==
            bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"))
        ) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = token.call(
                abi.encodeWithSelector(
                    selector,
                    svm.createAddress("from"),
                    svm.createAddress("to"),
                    svm.createUint256("tokenId"),
                    svm.createBytes(96, "YOLO")
                )
            );
        } else {
            bytes memory args = svm.createBytes(1_024, "WAGMI");
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = address(token).call(abi.encodePacked(selector, args));
        }
        vm.assume(success);
        vm.stopPrank();

        assert(erc721.balanceOf(caller) <= oldBalanceCaller);
        assert(erc721.balanceOf(other) >= oldBalanceOther);
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/a16z/halmos/blob/main/examples/tokens/ERC721/test/ERC721Test.sol.
     */
    function testHalmosTransferFrom(
        address caller,
        address from,
        address to,
        address other,
        uint256 tokenId,
        uint256 otherTokenId
    ) public {
        vm.assume(other != from && other != to && otherTokenId != tokenId);

        uint256 oldBalanceFrom = erc721.balanceOf(from);
        uint256 oldBalanceTo = erc721.balanceOf(to);
        uint256 oldBalanceOther = erc721.balanceOf(other);
        address oldOwner = erc721.ownerOf(tokenId);
        address oldOtherTokenOwner = erc721.ownerOf(otherTokenId);
        address owner = erc721.ownerOf(tokenId);
        bool approved = (caller == owner ||
            erc721.isApprovedForAll(owner, caller) ||
            erc721.getApproved(tokenId) == caller);

        vm.startPrank(caller);
        if (svm.createBool("1337")) {
            erc721.transferFrom(from, to, tokenId);
        } else {
            erc721.safeTransferFrom(
                from,
                to,
                tokenId,
                svm.createBytes(96, "YOLO")
            );
        }
        vm.stopPrank();

        assert(from == oldOwner);
        assert(approved);
        assert(erc721.ownerOf(tokenId) == to);
        assert(erc721.getApproved(tokenId) == address(0));
        assert(erc721.ownerOf(otherTokenId) == oldOtherTokenOwner);

        if (from != to) {
            assert(erc721.balanceOf(from) < oldBalanceFrom);
            assert(erc721.balanceOf(from) == oldBalanceFrom - 1);
            assert(erc721.balanceOf(to) > oldBalanceTo);
            assert(erc721.balanceOf(to) == oldBalanceTo + 1);
        } else {
            assert(erc721.balanceOf(from) == oldBalanceFrom);
            assert(erc721.balanceOf(to) == oldBalanceTo);
        }

        assert(erc721.balanceOf(other) == oldBalanceOther);
    }
}
