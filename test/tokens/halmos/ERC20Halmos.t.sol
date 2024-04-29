// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20, ERC20Test} from "./ERC20Test.sol";

/**
 * @dev Sets the timeout (in milliseconds) for solving assertion
 * violation conditions; `0` means no timeout.
 * @custom:halmos --solver-timeout-assertion 0
 */
contract ERC20TestHalmos is ERC20Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "WAGMI";
    uint8 private constant _DECIMALS = 18;
    string private constant _NAME_EIP712 = "MyToken";
    string private constant _VERSION_EIP712 = "1";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    /**
     * @dev Sets timeout (in milliseconds) for solving branching
     * conditions; `0` means no timeout.
     * @custom:halmos --solver-timeout-branching 1000
     */
    function setUp() public override {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _DECIMALS,
            _INITIAL_SUPPLY,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        /**
         * @dev Halmos does not currently work with the latest Vyper jump-table-based
         * dispatchers: https://github.com/a16z/halmos/issues/253. For Halmos-based tests,
         * we therefore disable the optimiser.
         */
        erc20 = IERC20(
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "ERC20Mock",
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

    function testHalmosAssertNoBackdoor(
        bytes4 selector,
        address caller,
        address other
    ) public {
        bytes memory args = svm.createBytes(1_024, "WAGMI");
        checkNoBackdoor(selector, args, caller, other);
    }
}
