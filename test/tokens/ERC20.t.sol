// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IERC20Extended} from "../../test/tokens/interfaces/IERC20Extended.sol";

/**
 UNIT TEST COVERAGE
 - constructor [DONE]
 - transfer
 - approve
 - transferFrom
 - increase_allowance
 - decrease_allowance
 - burn
 - burn_from
 - mint [DONE]
 - set_minter [DONE]
 - permit
 - transfer_ownership [DONE]
 - renounce_ownership [DONE]
*/
contract ERC20Test is Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "WAGMI";
    string private constant _NAME_EIP712 = "MyToken";
    string private constant _VERSION_EIP712 = "1";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC20Extended private ERC20Extended;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event RoleMinterChanged(address indexed minter, bool status);

    function setUp() public {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _INITIAL_SUPPLY,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC20Extended = IERC20Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC20", args)
        );
    }

    function testInitialSetup() public {
        address deployer = address(vyperDeployer);
        uint256 multiplier = 10**uint256(ERC20Extended.decimals());
        assertTrue(ERC20Extended.decimals() == 18);
        assertEq(ERC20Extended.name(), _NAME);
        assertEq(ERC20Extended.symbol(), _SYMBOL);
        assertTrue(ERC20Extended.totalSupply() == _INITIAL_SUPPLY * multiplier);
        assertTrue(
            ERC20Extended.balanceOf(deployer) == _INITIAL_SUPPLY * multiplier
        );
        assertTrue(ERC20Extended.owner() == deployer);
        assertTrue(ERC20Extended.is_minter(deployer));
    }

    function testSetMinterSuccess() public {
        address owner = address(vyperDeployer);
        address minter = vm.addr(1);
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, true);
        ERC20Extended.set_minter(minter, true);
        assertTrue(ERC20Extended.is_minter(minter));

        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, false);
        ERC20Extended.set_minter(minter, false);
        assertTrue(!ERC20Extended.is_minter(minter));
    }

    function testSetMinterNonOwner() public {
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ERC20Extended.set_minter(vm.addr(1), true);
    }

    function testSetMinterToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: minter is the zero address"));
        ERC20Extended.set_minter(address(0), true);
    }

    function testSetMinterRemoveOwnerAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("AccessControl: minter is owner address"));
        ERC20Extended.set_minter(address(vyperDeployer), false);
    }

    function testMintSuccess() public {
        address minter = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 amount = type(uint8).max;
        uint256 multiplier = 10**uint256(ERC20Extended.decimals());
        vm.startPrank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), owner, amount);
        ERC20Extended.mint(owner, amount);
        assertTrue(ERC20Extended.balanceOf(owner) == amount);
        assertTrue(
            ERC20Extended.totalSupply() ==
                (amount + _INITIAL_SUPPLY * multiplier)
        );
        vm.stopPrank();
    }

    function testMintNonMinter() public {
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC20Extended.mint(vm.addr(1), 100);
    }

    function testMintToZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        ERC20Extended.mint(address(0), 100);
    }

    function testMintOverflow() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert();
        ERC20Extended.mint(vm.addr(1), type(uint256).max);
    }

    function testHasOwner() public {
        assertEq(ERC20Extended.owner(), address(vyperDeployer));
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = address(vyperDeployer);
        address newOwner = vm.addr(1);
        vm.startPrank(oldOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC20Extended.transfer_ownership(newOwner);
        assertEq(ERC20Extended.owner(), newOwner);
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("AccessControl: caller is not the owner"));
        ERC20Extended.transfer_ownership(vm.addr(1));
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
        vm.expectEmit(true, true, false, false);
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
