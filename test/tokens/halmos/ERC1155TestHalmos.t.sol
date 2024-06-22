// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";

import {IERC1155Extended} from "../interfaces/IERC1155Extended.sol";

/**
 * @dev Sets the timeout (in milliseconds) for solving assertion
 * violation conditions; `0` means no timeout.
 * @notice Halmos currently does not support the new native `assert`
 * cheatcodes in `forge-std` `v1.8.0` and above.
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

    function extcodesize(address addr) internal view returns (uint size) {
        assembly { size := extcodesize(addr) }
    }

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
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "erc1155_mock",
                args,
                "shanghai",
                "none"
            )
        );

        address deployer = address(vyperDeployer);
        token = address(erc1155);
        holders = new address[](3);
        holders[0] = address(0x1337);
        holders[1] = address(0x31337);
        holders[2] = address(0xbA5eD);

        /**
         * @dev Assume holders are EOAs to avoid multiple paths that occur due
         * to safeTransferFrom (specifically `_check_on_erc1155_received`)
         * depending on contract vs EOA cases.
         */
        vm.assume(extcodesize(holders[0]) == 0);
        vm.assume(extcodesize(holders[1]) == 0);
        vm.assume(extcodesize(holders[2]) == 0);

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
            IERC1155Extended(token)._customMint(
                deployer,
                tokenIds[i],
                amounts[i]
            );
        }
        erc1155.safeTransferFrom(
            deployer,
            holders[0],
            tokenIds[0],
            amounts[0],
            new bytes(0)
        );
        erc1155.safeTransferFrom(
            deployer,
            holders[0],
            tokenIds[1],
            amounts[1],
            new bytes(42)
        );
        erc1155.safeTransferFrom(
            deployer,
            holders[1],
            tokenIds[2],
            amounts[2],
            new bytes(96)
        );
        erc1155.safeTransferFrom(
            deployer,
            holders[2],
            tokenIds[3],
            amounts[3],
            new bytes(1_024)
        );
        vm.stopPrank();

        vm.startPrank(holders[0]);
        erc1155.setApprovalForAll(holders[2], true);
        vm.stopPrank();

        vm.startPrank(holders[1]);
        erc1155.setApprovalForAll(holders[2], true);
        vm.stopPrank();
    }

    /**
     * @dev Currently commented out due to performance and reverting path issues in Halmos.
     */
    function testHalmosAssertNoBackdoor(
        bytes4 selector,
        address caller,
        address other
    ) public {
        /**
         * @dev Using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(caller != other);
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

        uint256[] memory oldBalanceCaller = erc1155.balanceOfBatch(
            callers,
            tokenIds
        );
        uint256[] memory oldBalanceOther = erc1155.balanceOfBatch(
            others,
            tokenIds
        );

        vm.startPrank(caller);
        bool success;
        if (selector == IERC1155.safeTransferFrom.selector) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = token.call(
                abi.encodeWithSelector(
                    selector,
                    svm.createAddress("from"),
                    svm.createAddress("to"),
                    svm.createUint256("tokenId"),
                    svm.createUint256("amount"),
                    svm.createBytes(96, "YOLO")
                )
            );
        } else if (selector == IERC1155.safeBatchTransferFrom.selector
                || selector == IERC1155Extended.burn_batch.selector
        ) {
            uint256[] memory ids = new uint256[](5);
            uint256[] memory values = new uint256[](5);
            for (uint256 i = 0; i < ids.length; i++) {
                ids[i] = svm.createUint256("ids");
                values[i] = svm.createUint256("values");
            }
            bytes memory data;
            if (selector == IERC1155.safeBatchTransferFrom.selector) {
                data = abi.encodeWithSelector(
                    selector,
                    svm.createAddress("from"),
                    svm.createAddress("to"),
                    ids,
                    values,
                    svm.createBytes(96, "YOLO")
                );
            } else {
                data = abi.encodeWithSelector(
                    selector,
                    svm.createAddress("owner"),
                    ids,
                    values
                );
            }
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = token.call(data);
        } else if (selector == IERC1155Extended.set_uri.selector) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = token.call(
                abi.encodeWithSelector(
                    selector,
                    svm.createUint256("id"),
                    svm.createBytes(96, "uri")
                )
            );
        } else {
            bytes memory args = svm.createBytes(1_024, "WAGMI");
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = address(token).call(abi.encodePacked(selector, args));
        }
        vm.assume(success);
        vm.stopPrank();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assert(
                erc1155.balanceOf(caller, tokenIds[i]) <= oldBalanceCaller[i]
            );
            assert(erc1155.balanceOf(other, tokenIds[i]) >= oldBalanceOther[i]);
        }
    }

    function testHalmosSafeTransferFrom(
        address caller,
        address from,
        address to,
        address other
    ) public {
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
            erc1155.safeTransferFrom(
                from,
                to,
                tokenIds[0],
                amounts[0],
                svm.createBytes(96, "YOLO")
            );
        } else {
            erc1155.safeBatchTransferFrom(
                from,
                to,
                tokenIds,
                amounts,
                svm.createBytes(96, "YOLO")
            );
        }
        vm.stopPrank();

        (from == caller) ? assert(!approved) : assert(approved);

        uint256 newBalanceFrom = erc1155.balanceOf(from, tokenIds[0]);
        uint256 newBalanceTo = erc1155.balanceOf(to, tokenIds[0]);
        uint256 newBalanceOther = erc1155.balanceOf(other, tokenIds[0]);

        if (from != to) {
            assert(newBalanceFrom == oldBalanceFrom - amounts[0]);
            assert(newBalanceTo == oldBalanceTo + amounts[0]);
        } else {
            assert(newBalanceFrom == oldBalanceFrom);
            assert(newBalanceTo == oldBalanceTo);
        }

        assert(newBalanceOther == oldBalanceOther);
    }
}
