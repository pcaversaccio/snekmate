// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";

import {IERC721Extended} from "../interfaces/IERC721Extended.sol";

/**
 * @dev Set the timeout (in milliseconds) for solving assertion violation
 * conditions; `0` means no timeout.
 * @custom:halmos --solver-timeout-assertion 0
 */
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

    /**
     * @dev Set the timeout (in milliseconds) for solving branching conditions;
     * `0` means no timeout.
     * @custom:halmos --solver-timeout-branching 1000
     */
    function setUp() public {
        bytes memory args = abi.encode(_NAME, _SYMBOL, _BASE_URI, _NAME_EIP712, _VERSION_EIP712);
        /**
         * @dev Halmos does not currently work with the latest Vyper jump-table-based
         * dispatchers: https://github.com/a16z/halmos/issues/253. For Halmos-based tests,
         * we therefore disable the optimiser.
         */
        erc721 = IERC721(
            vyperDeployer.deployContract("src/snekmate/tokens/mocks/", "erc721_mock", args, "prague", "none")
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
    function testHalmosAssertNoBackdoor(address caller, address other) public {
        /**
         * @dev To verify the correct behaviour of the Vyper compiler for `view` and `pure`
         * functions, we include read-only functions in the calldata creation.
         */
        bytes memory data = svm.createCalldata("IERC721Extended.sol", "IERC721Extended", true);
        bytes4 selector = bytes4(data);

        /**
         * @dev Using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(caller != other);
        vm.assume(selector != IERC721Metadata.tokenURI.selector);
        vm.assume(selector != IERC721Extended._customMint.selector);
        vm.assume(selector != IERC721Extended.safe_mint.selector);
        for (uint256 i = 0; i < holders.length; i++) {
            vm.assume(!erc721.isApprovedForAll(holders[i], caller));
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.assume(erc721.getApproved(tokenIds[i]) != caller);
        }

        uint256 oldBalanceCaller = erc721.balanceOf(caller);
        uint256 oldBalanceOther = erc721.balanceOf(other);

        vm.startPrank(caller);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(data);
        vm.assume(success);
        vm.stopPrank();

        uint256 newBalanceCaller = erc721.balanceOf(caller);
        uint256 newBalanceOther = erc721.balanceOf(other);

        assertLe(newBalanceCaller, oldBalanceCaller);
        assertGe(newBalanceOther, oldBalanceOther);
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/a16z/halmos/blob/main/examples/tokens/ERC721/test/ERC721Test.sol.
     */
    function testHalmosSafeTransferFrom(
        address caller,
        address from,
        address to,
        address other,
        uint256 tokenId,
        uint256 otherTokenId
    ) public {
        /**
         * @dev Using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(other != from);
        vm.assume(other != to);
        vm.assume(otherTokenId != tokenId);

        uint256 oldBalanceFrom = erc721.balanceOf(from);
        uint256 oldBalanceTo = erc721.balanceOf(to);
        uint256 oldBalanceOther = erc721.balanceOf(other);

        address oldOwner = erc721.ownerOf(tokenId);
        address oldOtherTokenOwner = erc721.ownerOf(otherTokenId);
        bool approved = (caller == oldOwner ||
            erc721.isApprovedForAll(oldOwner, caller) ||
            erc721.getApproved(tokenId) == caller);

        vm.startPrank(caller);
        if (svm.createBool("1337")) {
            erc721.transferFrom(from, to, tokenId);
        } else {
            erc721.safeTransferFrom(from, to, tokenId, svm.createBytes(96, "YOLO"));
        }
        vm.stopPrank();

        assertEq(from, oldOwner);
        assertTrue(approved);
        assertEq(erc721.ownerOf(tokenId), to);
        assertEq(erc721.getApproved(tokenId), address(0));
        assertEq(erc721.ownerOf(otherTokenId), oldOtherTokenOwner);

        uint256 newBalanceFrom = erc721.balanceOf(from);
        uint256 newBalanceTo = erc721.balanceOf(to);
        uint256 newBalanceOther = erc721.balanceOf(other);

        if (from != to) {
            assertEq(newBalanceFrom, oldBalanceFrom - 1);
            assertEq(newBalanceTo, oldBalanceTo + 1);
        } else {
            assertEq(newBalanceFrom, oldBalanceFrom);
            assertEq(newBalanceTo, oldBalanceTo);
        }

        assertEq(newBalanceOther, oldBalanceOther);
    }
}
