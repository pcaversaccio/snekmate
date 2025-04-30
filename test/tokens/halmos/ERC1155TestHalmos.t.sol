// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "openzeppelin/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import {IERC1155Extended} from "../interfaces/IERC1155Extended.sol";

/**
 * @dev Set the timeout (in milliseconds) for solving assertion violation
 * conditions; `0` means no timeout.
 * @custom:halmos --solver-timeout-assertion 0
 */
contract ERC1155TestHalmos is Test, SymTest {
    string private constant _BASE_URI = "https://www.wagmi.xyz/";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IERC1155 private erc1155;
    address private token;
    address[] private holders;
    uint256[] private tokenIds;
    uint256[] private amounts;

    /**
     * @dev Set the timeout (in milliseconds) for solving branching conditions;
     * `0` means no timeout.
     * @custom:halmos --solver-timeout-branching 1000
     */
    function setUp() public {
        bytes memory args = abi.encode(_BASE_URI);
        /**
         * @dev Halmos does not currently work with the latest Vyper jump-table-based
         * dispatchers: https://github.com/a16z/halmos/issues/253. For Halmos-based tests,
         * we therefore disable the optimiser. Furthermore, Halmos does not currently
         * work with the EVM version `cancun`: https://github.com/a16z/halmos/issues/290.
         * For Halmos-based tests, we therefore use the EVM version `shanghai`.
         */
        erc1155 = IERC1155(
            vyperDeployer.deployContract("src/snekmate/tokens/mocks/", "erc1155_mock", args, "shanghai", "none")
        );

        address deployer = address(vyperDeployer);
        token = address(erc1155);
        holders = new address[](3);
        holders[0] = address(0x1337);
        holders[1] = address(0x31337);
        holders[2] = address(0xbA5eD);

        /**
         * @dev Assume that the holders are EOAs to avoid multiple paths that can
         * occur due to `safeTransferFrom` and `safeBatchTransferFrom` (specifically
         * `_check_on_erc1155_received` and `_check_on_erc1155_batch_received`)
         * depending on whether there is a contract or an EOA. Please note that
         * using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(holders[0].code.length == 0);
        vm.assume(holders[1].code.length == 0);
        vm.assume(holders[2].code.length == 0);

        tokenIds = new uint256[](5);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 3;
        tokenIds[4] = 4;

        amounts = new uint256[](5);
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 10;
        amounts[3] = 20;
        amounts[4] = 50;

        vm.startPrank(deployer);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC1155Extended(token)._customMint(deployer, tokenIds[i], amounts[i]);
        }
        erc1155.safeTransferFrom(deployer, holders[0], tokenIds[0], amounts[0], new bytes(0));
        erc1155.safeTransferFrom(deployer, holders[0], tokenIds[1], amounts[1], new bytes(42));
        erc1155.safeTransferFrom(deployer, holders[1], tokenIds[2], amounts[2], new bytes(96));
        erc1155.safeTransferFrom(deployer, holders[2], tokenIds[3], amounts[3], new bytes(1_024));
        vm.stopPrank();

        vm.startPrank(holders[0]);
        erc1155.setApprovalForAll(holders[2], true);
        vm.stopPrank();

        vm.startPrank(holders[1]);
        erc1155.setApprovalForAll(holders[2], true);
        vm.stopPrank();
    }

    /**
     * Set the length of the dynamically-sized arrays in the `IERC1155` interface.
     * @custom:halmos --array-lengths ids={5},values={5},amounts={5}
     */
    function testHalmosAssertNoBackdoor(address caller, address other) public {
        /**
         * @dev To verify the correct behaviour of the Vyper compiler for `view` and `pure`
         * functions, we include read-only functions in the calldata creation.
         */
        bytes memory data = svm.createCalldata("IERC1155Extended.sol", "IERC1155Extended", true);
        bytes4 selector = bytes4(data);

        /**
         * @dev Using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(caller != other);
        vm.assume(selector != IERC1155MetadataURI.uri.selector);
        vm.assume(selector != IERC1155Extended.set_uri.selector);
        vm.assume(selector != IERC1155Extended._customMint.selector);
        vm.assume(selector != IERC1155Extended.safe_mint.selector);
        vm.assume(selector != IERC1155Extended.safe_mint_batch.selector);
        for (uint256 i = 0; i < holders.length; i++) {
            vm.assume(!erc1155.isApprovedForAll(holders[i], caller));
        }

        address[] memory callers = new address[](tokenIds.length);
        address[] memory others = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            callers[i] = caller;
            others[i] = other;
        }

        uint256[] memory oldBalanceCaller = erc1155.balanceOfBatch(callers, tokenIds);
        uint256[] memory oldBalanceOther = erc1155.balanceOfBatch(others, tokenIds);

        vm.startPrank(caller);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(data);
        vm.assume(success);
        vm.stopPrank();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertLe(erc1155.balanceOf(caller, tokenIds[i]), oldBalanceCaller[i]);
            assertGe(erc1155.balanceOf(other, tokenIds[i]), oldBalanceOther[i]);
        }
    }

    function testHalmosSafeTransferFrom(address caller, address from, address to, address other) public {
        /**
         * @dev Using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(other != from);
        vm.assume(other != to);

        uint256 oldBalanceFrom = erc1155.balanceOf(from, tokenIds[0]);
        uint256 oldBalanceTo = erc1155.balanceOf(to, tokenIds[0]);
        uint256 oldBalanceOther = erc1155.balanceOf(other, tokenIds[0]);
        bool approved = erc1155.isApprovedForAll(from, caller);

        vm.startPrank(caller);
        if (svm.createBool("1337")) {
            erc1155.safeTransferFrom(from, to, tokenIds[0], amounts[0], svm.createBytes(96, "YOLO"));
        } else {
            erc1155.safeBatchTransferFrom(from, to, tokenIds, amounts, svm.createBytes(96, "YOLO"));
        }
        vm.stopPrank();

        (from == caller) ? assertTrue(!approved) : assertTrue(approved);

        uint256 newBalanceFrom = erc1155.balanceOf(from, tokenIds[0]);
        uint256 newBalanceTo = erc1155.balanceOf(to, tokenIds[0]);
        uint256 newBalanceOther = erc1155.balanceOf(other, tokenIds[0]);

        if (from != to) {
            assertEq(newBalanceFrom, oldBalanceFrom - amounts[0]);
            assertEq(newBalanceTo, oldBalanceTo + amounts[0]);
        } else {
            assertEq(newBalanceFrom, oldBalanceFrom);
            assertEq(newBalanceTo, oldBalanceTo);
        }

        assertEq(newBalanceOther, oldBalanceOther);
    }
}
