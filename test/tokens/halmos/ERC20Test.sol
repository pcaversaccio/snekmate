// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/**
 * @title ERC20Test
 * @author pcaversaccio
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/a16z/halmos/blob/main/examples/tokens/ERC20/test/ERC20Test.sol.
 * @dev Helper contract to formally verify the functions
 * `transfer` and `transferFrom` in the `ERC20Mock` contract.
 */
abstract contract ERC20Test is Test, SymTest {
    IERC20 internal erc20;
    address internal token;
    address[] internal holders;

    function setUp() public virtual;

    /**
     * @dev Ensures that there is no backdoor in the token transfer functions.
     * @param selector The 4-byte function selector to be called.
     * @param args The ABI-encoded calldata payload for the function selector.
     * @param caller The 20-byte caller address.
     * @param other The 20-byte random address.
     */
    function checkNoBackdoor(
        bytes4 selector,
        bytes memory args,
        address caller,
        address other
    ) public virtual {
        vm.assume(other != caller);

        uint256 oldBalanceOther = erc20.balanceOf(other);
        uint256 oldAllowance = erc20.allowance(other, caller);

        vm.startPrank(caller);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(abi.encodePacked(selector, args));
        vm.assume(success);
        vm.stopPrank();

        uint256 newBalanceOther = erc20.balanceOf(other);

        if (newBalanceOther < oldBalanceOther) {
            assert(oldAllowance >= oldBalanceOther - newBalanceOther);
        }
    }
}
