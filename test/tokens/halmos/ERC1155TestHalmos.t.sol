// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

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

    function setUp() public {
        bytes memory args = abi.encode(_BASE_URI);
        erc1155 = IERC1155(
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "ERC1155Mock",
                args
            )
        );

        address deployer = address(vyperDeployer);
        token = address(erc1155);
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
            new bytes(1_337)
        );
        erc1155.safeTransferFrom(
            deployer,
            holders[2],
            tokenIds[3],
            amounts[3],
            new bytes(31_337)
        );
        vm.stopPrank();

        vm.startPrank(holders[0]);
        erc1155.setApprovalForAll(holders[2], true);
        vm.stopPrank();

        vm.startPrank(holders[1]);
        erc1155.setApprovalForAll(holders[2], true);
        vm.stopPrank();
    }

    function testHalmosAssertNoBackdoor(
        bytes4 selector,
        address caller,
        address other
    ) public {
        vm.assume(
            caller != other &&
                selector != IERC1155Extended._customMint.selector &&
                selector != IERC1155Extended.safe_mint.selector &&
                selector != IERC1155Extended.safe_mint_batch.selector
        );
        for (uint256 i = 0; i < holders.length; i++) {
            vm.assume(!erc1155.isApprovedForAll(holders[i], caller));
        }

        address[] memory callers;
        address[] memory others;
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
        } else if (selector == IERC1155.safeBatchTransferFrom.selector) {
            uint256[] memory ids = new uint256[](5);
            uint256[] memory values = new uint256[](5);
            for (uint256 i = 0; i < ids.length; i++) {
                ids[i] = svm.createUint256("ids");
                values[i] = svm.createUint256("values");
            }
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = token.call(
                abi.encodeWithSelector(
                    selector,
                    svm.createAddress("from"),
                    svm.createAddress("to"),
                    ids,
                    values,
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

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assert(
                erc1155.balanceOf(caller, tokenIds[i]) <= oldBalanceCaller[i]
            );
            assert(erc1155.balanceOf(other, tokenIds[i]) >= oldBalanceOther[i]);
        }
    }

    function testHalmosTransferFrom(
        address caller,
        address from,
        address to,
        address other
    ) public {
        vm.assume(other != from && other != to);

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

        assert(!approved);

        if (from != to) {
            assert(erc1155.balanceOf(from, tokenIds[0]) < oldBalanceFrom);
            assert(erc1155.balanceOf(from, tokenIds[0]) == oldBalanceFrom - 1);
            assert(erc1155.balanceOf(to, tokenIds[0]) > oldBalanceTo);
            assert(erc1155.balanceOf(to, tokenIds[0]) == oldBalanceTo + 1);
        } else {
            assert(erc1155.balanceOf(from, tokenIds[0]) == oldBalanceFrom);
            assert(erc1155.balanceOf(to, tokenIds[0]) == oldBalanceTo);
        }

        assert(erc1155.balanceOf(other, tokenIds[0]) == oldBalanceOther);
    }
}
