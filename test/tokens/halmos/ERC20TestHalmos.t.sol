// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {IERC20Extended} from "../interfaces/IERC20Extended.sol";

/**
 * @dev Sets the timeout (in milliseconds) for solving assertion
 * violation conditions; `0` means no timeout.
 * @custom:halmos --solver-timeout-assertion 0
 */
contract ERC20TestHalmos is Test, SymTest {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "WAGMI";
    string private constant _NAME_EIP712 = "MyToken";
    string private constant _VERSION_EIP712 = "1";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IERC20 private erc20;
    address private token;
    address[] private holders;

    /**
     * @dev Sets timeout (in milliseconds) for solving branching
     * conditions; `0` means no timeout.
     * @custom:halmos --solver-timeout-branching 1000
     */
    function setUpSymbolic(uint256 initialSupply_) public {
        uint8 decimals = uint8(svm.createUint(8, "decimals"));
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            decimals,
            initialSupply_,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        /**
         * @dev Halmos does not currently work with the latest Vyper jump-table-based
         * dispatchers: https://github.com/a16z/halmos/issues/253. For Halmos-based tests,
         * we therefore disable the optimiser. Furthermore, Halmos does not currently
         * work with the EVM version `cancun`: https://github.com/a16z/halmos/issues/290.
         * For Halmos-based tests, we therefore use the EVM version `shanghai`.
         */
        erc20 = IERC20(
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "erc20_mock",
                args,
                "shanghai",
                "none"
            )
        );

        address deployer = address(vyperDeployer);
        token = address(erc20);
        holders = new address[](3);
        holders[0] = address(0x1337);
        holders[1] = address(0x31337);
        holders[2] = address(0xbA5eD);

        for (uint256 i = 0; i < holders.length; i++) {
            address account = holders[i];
            uint256 balance = svm.createUint256("balance");
            vm.assume(balance <= erc20.balanceOf(deployer));

            vm.startPrank(deployer);
            erc20.transfer(account, balance);
            vm.stopPrank();

            for (uint256 j = 0; j < i; j++) {
                address other = holders[j];
                uint256 amount = svm.createUint256("amount");
                vm.startPrank(account);
                erc20.approve(other, amount);
                vm.stopPrank();
            }
        }
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/a16z/halmos/blob/main/examples/tokens/ERC20/test/ERC20Test.sol.
     */
    function testHalmosAssertNoBackdoor(address caller, address other) public {
        vm.assume(other != caller);

        uint256 oldBalanceOther = erc20.balanceOf(other);
        uint256 oldAllowance = erc20.allowance(other, caller);

        vm.startPrank(caller);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(svm.createCalldata("IERC20Extended"));
        vm.assume(success);
        vm.stopPrank();

        uint256 newBalanceOther = erc20.balanceOf(other);

        if (newBalanceOther < oldBalanceOther) {
            assertGe(oldAllowance, oldBalanceOther - newBalanceOther);
        }
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/a16z/halmos/blob/main/examples/tokens/ERC20/test/ERC20Test.sol.
     */
    function testHalmosTransfer(
        address sender,
        address receiver,
        address other,
        uint256 amount
    ) public {
        /**
         * @dev Using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(other != sender);
        vm.assume(other != receiver);

        uint256 oldBalanceSender = erc20.balanceOf(sender);
        uint256 oldBalanceReceiver = erc20.balanceOf(receiver);
        uint256 oldBalanceOther = erc20.balanceOf(other);

        vm.startPrank(sender);
        erc20.transfer(receiver, amount);
        vm.stopPrank();

        uint256 newBalanceSender = erc20.balanceOf(sender);
        uint256 newBalanceReceiver = erc20.balanceOf(receiver);
        uint256 newBalanceOther = erc20.balanceOf(other);

        if (sender != receiver) {
            assertEq(newBalanceSender, oldBalanceSender - amount);
            assertEq(newBalanceReceiver, oldBalanceReceiver + amount);
        } else {
            assertEq(newBalanceSender, oldBalanceSender);
            assertEq(newBalanceReceiver, oldBalanceReceiver);
        }

        assertEq(newBalanceOther, oldBalanceOther);
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/a16z/halmos/blob/main/examples/tokens/ERC20/test/ERC20Test.sol.
     */
    function testHalmosTransferFrom(
        address caller,
        address from,
        address to,
        address other,
        uint256 amount
    ) public {
        /**
         * @dev Using a single `assume` with conjunctions would result in the creation of
         * multiple paths, negatively impacting performance.
         */
        vm.assume(other != from);
        vm.assume(other != to);

        uint256 oldBalanceFrom = erc20.balanceOf(from);
        uint256 oldBalanceTo = erc20.balanceOf(to);
        uint256 oldBalanceOther = erc20.balanceOf(other);
        uint256 oldAllowance = erc20.allowance(from, caller);

        vm.startPrank(caller);
        erc20.transferFrom(from, to, amount);
        vm.stopPrank();

        uint256 newBalanceFrom = erc20.balanceOf(from);
        uint256 newBalanceTo = erc20.balanceOf(to);

        if (from != to) {
            assertEq(newBalanceFrom, oldBalanceFrom - amount);
            assertEq(newBalanceTo, oldBalanceTo + amount);
            assertGe(oldAllowance, amount);
            assertTrue(
                oldAllowance == type(uint256).max ||
                    erc20.allowance(from, caller) == oldAllowance - amount
            );
        } else {
            assertEq(newBalanceFrom, oldBalanceFrom);
            assertEq(newBalanceTo, oldBalanceTo);
        }

        assertEq(erc20.balanceOf(other), oldBalanceOther);
    }
}
