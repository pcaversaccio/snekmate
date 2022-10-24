// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IERC20Extended} from "../../test/tokens/interfaces/IERC20Extended.sol";

import {console} from "../../lib/forge-std/src/console.sol";

/**
 UNIT TEST SUITE
 - constructor
 - transfer
 - approve
 - transferFrom
 - increase_allowance
 - decrease_allowance
 - burn
 - burn_from
 - mint
 - set_minter
 - permit
 - transfer_ownership [DONE]
 - renounce_ownership [DONE]
*/
contract ERC20Test is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC20Extended private ERC20Extended;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setUp() public {
        ERC20Extended = IERC20Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC20")
        );
    }

    function testHasOwner() public {
        assertEq(ERC20Extended.owner(), address(vyperDeployer));
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC20Extended.transfer_ownership(newOwner);
        assertEq(ERC20Extended.owner(), newOwner);
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ERC20Extended.transfer_ownership(address(vm.addr(1)));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: new owner is the zero address"));
        ERC20Extended.transfer_ownership(address(0));
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = address(0);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC20Extended.renounce_ownership();
        assertEq(ERC20Extended.owner(), newOwner);
        assertTrue(ERC20Extended.is_minter(oldOwner) == false);
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ERC20Extended.renounce_ownership();
    }
}
