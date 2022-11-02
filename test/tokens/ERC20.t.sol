// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IERC20Extended} from "../../test/tokens/interfaces/IERC20Extended.sol";

contract ERC20Test is Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "WAGMI";
    string private constant _NAME_EIP712 = "MyToken";
    string private constant _VERSION_EIP712 = "1";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 private constant _PERMIT_TYPE_HASH =
        keccak256(
            bytes(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
            )
        );

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC20Extended private ERC20Extended;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _CACHED_DOMAIN_SEPARATOR;

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
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                address(ERC20Extended)
            )
        );
    }

    function testInitialSetup() public {
        address deployer = address(vyperDeployer);
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
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

    function testTotalSupply() public {
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
        assertTrue(ERC20Extended.totalSupply() == _INITIAL_SUPPLY * multiplier);
    }

    function testBalanceOf() public {
        address deployer = address(vyperDeployer);
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
        assertTrue(
            ERC20Extended.balanceOf(deployer) == _INITIAL_SUPPLY * multiplier
        );
        assertTrue(ERC20Extended.balanceOf(vm.addr(1)) == 0);
    }

    function testTransferSuccess() public {
        address owner = address(vyperDeployer);
        address to = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transfer(to, amount);
        assertTrue(returnValue);
        assertTrue(ERC20Extended.balanceOf(owner) == 0);
        assertTrue(ERC20Extended.balanceOf(to) == amount);
        vm.stopPrank();
    }

    function testTransferInvalidAmount() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        ERC20Extended.transfer(vm.addr(1), type(uint256).max);
    }

    function testTransferZeroTokens() public {
        address owner = address(vyperDeployer);
        address to = vm.addr(1);
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 amount = 0;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transfer(to, amount);
        assertTrue(returnValue);
        assertTrue(ERC20Extended.balanceOf(owner) == balance);
        assertTrue(ERC20Extended.balanceOf(to) == amount);
        vm.stopPrank();
    }

    function testTransferToZeroAddress() public {
        address owner = address(vyperDeployer);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: transfer to the zero address"));
        ERC20Extended.transfer(address(0), amount);
    }

    function testTransferFromZeroAddress() public {
        address owner = address(vyperDeployer);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.burn(amount);
        vm.prank(address(0));
        vm.expectRevert(bytes("ERC20: transfer from the zero address"));
        ERC20Extended.transfer(vm.addr(1), amount);
    }

    function testApproveSuccessCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue = ERC20Extended.approve(spender, amount);
        assertTrue(returnValue);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        vm.stopPrank();
    }

    function testApproveSuccessCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 firstAmount = 100;
        uint256 secondAmount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, firstAmount);
        bool returnValue1 = ERC20Extended.approve(spender, firstAmount);
        assertTrue(ERC20Extended.allowance(owner, spender) == firstAmount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, secondAmount);
        bool returnValue2 = ERC20Extended.approve(spender, secondAmount);
        assertTrue(returnValue2);
        assertTrue(ERC20Extended.allowance(owner, spender) == secondAmount);
        vm.stopPrank();
    }

    function testApproveExceedingBalanceCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = type(uint128).max;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue = ERC20Extended.approve(spender, amount);
        assertTrue(returnValue);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        vm.stopPrank();
    }

    function testApproveExceedingBalanceCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 firstAmount = 100;
        uint256 secondAmount = type(uint128).max;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, firstAmount);
        bool returnValue1 = ERC20Extended.approve(spender, firstAmount);
        assertTrue(ERC20Extended.allowance(owner, spender) == firstAmount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, secondAmount);
        bool returnValue2 = ERC20Extended.approve(spender, secondAmount);
        assertTrue(returnValue2);
        assertTrue(ERC20Extended.allowance(owner, spender) == secondAmount);
        vm.stopPrank();
    }

    function testApproveToZeroAddress() public {
        address owner = address(vyperDeployer);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: approve to the zero address"));
        ERC20Extended.approve(address(0), amount);
    }

    function testApproveFromZeroAddress() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("ERC20: approve from the zero address"));
        ERC20Extended.approve(vm.addr(1), type(uint256).max);
    }

    function testTransferFromSuccess() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        address to = vm.addr(2);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(
            owner,
            spender,
            ERC20Extended.allowance(owner, spender) - amount
        );
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transferFrom(owner, to, amount);
        assertTrue(returnValue);
        assertTrue(ERC20Extended.balanceOf(owner) == 0);
        assertTrue(ERC20Extended.balanceOf(to) == amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == 0);
        vm.stopPrank();
    }

    function testTransferFromExceedingBalance() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        ERC20Extended.transferFrom(owner, vm.addr(2), amount);
    }

    function testTransferFromInsufficientAllowanceCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.transferFrom(owner, vm.addr(2), amount);
    }

    function testTransferFromInsufficientAllowanceCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.transferFrom(owner, vm.addr(2), amount);
    }

    function testTransferFromUnlimitedAllowance() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        address to = vm.addr(2);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, type(uint256).max);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transferFrom(owner, to, amount);
        assertTrue(returnValue);
        assertTrue(ERC20Extended.balanceOf(owner) == 0);
        assertTrue(ERC20Extended.balanceOf(to) == amount);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == type(uint256).max
        );
        vm.stopPrank();
    }

    function testTransferFromToZeroAddress() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: transfer to the zero address"));
        ERC20Extended.transferFrom(owner, address(0), amount);
    }

    function testTransferFromFromZeroAddress() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("ERC20: approve from the zero address"));
        ERC20Extended.transferFrom(address(0), vm.addr(1), 0);
    }

    function testIncreaseAllowanceSuccessCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 addedAmount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, addedAmount);
        bool returnValue = ERC20Extended.increase_allowance(
            spender,
            addedAmount
        );
        assertTrue(returnValue);
        assertTrue(ERC20Extended.allowance(owner, spender) == addedAmount);
        vm.stopPrank();
    }

    function testIncreaseAllowanceSuccessCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = 100;
        uint256 addedAmount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue1 = ERC20Extended.approve(spender, amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount + addedAmount);
        bool returnValue2 = ERC20Extended.increase_allowance(
            spender,
            addedAmount
        );
        assertTrue(returnValue2);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == amount + addedAmount
        );
        vm.stopPrank();
    }

    function testIncreaseAllowanceExceedingBalanceCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 addedAmount = type(uint128).max;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, addedAmount);
        bool returnValue = ERC20Extended.increase_allowance(
            spender,
            addedAmount
        );
        assertTrue(returnValue);
        assertTrue(ERC20Extended.allowance(owner, spender) == addedAmount);
        vm.stopPrank();
    }

    function testIncreaseAllowanceExceedingBalanceCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = 100;
        uint256 addedAmount = type(uint128).max;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue1 = ERC20Extended.approve(spender, amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount + addedAmount);
        bool returnValue2 = ERC20Extended.increase_allowance(
            spender,
            addedAmount
        );
        assertTrue(returnValue2);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == amount + addedAmount
        );
        vm.stopPrank();
    }

    function testIncreaseAllowanceToZeroAddress() public {
        address owner = address(vyperDeployer);
        uint256 addedAmount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: approve to the zero address"));
        ERC20Extended.increase_allowance(address(0), addedAmount);
    }

    function testIncreaseAllowanceFromZeroAddress() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("ERC20: approve from the zero address"));
        ERC20Extended.increase_allowance(vm.addr(1), type(uint256).max);
    }

    function testDecreaseAllowanceSuccessCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        uint256 subtractedAmount = 100;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue1 = ERC20Extended.approve(spender, amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount - subtractedAmount);
        bool returnValue2 = ERC20Extended.decrease_allowance(
            spender,
            subtractedAmount
        );
        assertTrue(returnValue2);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == amount - subtractedAmount
        );
        vm.stopPrank();
    }

    function testDecreaseAllowanceSuccessCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        uint256 subtractedAmount = amount;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue1 = ERC20Extended.approve(spender, amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount - subtractedAmount);
        bool returnValue2 = ERC20Extended.decrease_allowance(
            spender,
            subtractedAmount
        );
        assertTrue(returnValue2);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == amount - subtractedAmount
        );
        vm.stopPrank();
    }

    function testDecreaseAllowanceExceedingBalanceCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = type(uint128).max;
        uint256 subtractedAmount = 100;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue1 = ERC20Extended.approve(spender, amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount - subtractedAmount);
        bool returnValue2 = ERC20Extended.decrease_allowance(
            spender,
            subtractedAmount
        );
        assertTrue(returnValue2);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == amount - subtractedAmount
        );
        vm.stopPrank();
    }

    function testDecreaseAllowanceExceedingBalanceCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = type(uint128).max;
        uint256 subtractedAmount = amount;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue1 = ERC20Extended.approve(spender, amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        assertTrue(returnValue1);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount - subtractedAmount);
        bool returnValue2 = ERC20Extended.decrease_allowance(
            spender,
            subtractedAmount
        );
        assertTrue(returnValue2);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == amount - subtractedAmount
        );
        vm.stopPrank();
    }

    function testDecreaseAllowanceInvalidAmountCase1() public {
        vm.prank(address(vyperDeployer));
        vm.expectRevert(bytes("ERC20: decreased allowance below zero"));
        ERC20Extended.decrease_allowance(vm.addr(1), 1);
    }

    function testDecreaseAllowanceInvalidAmountCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        uint256 subtractedAmount = ERC20Extended.balanceOf(owner) + 1;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue = ERC20Extended.approve(spender, amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == amount);
        assertTrue(returnValue);
        vm.expectRevert(bytes("ERC20: decreased allowance below zero"));
        ERC20Extended.decrease_allowance(spender, subtractedAmount);
        vm.stopPrank();
    }

    function testDecreaseAllowanceToZeroAddress() public {
        address owner = address(vyperDeployer);
        uint256 subtractedAmount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: decreased allowance below zero"));
        ERC20Extended.decrease_allowance(address(0), subtractedAmount);
    }

    function testDecreaseAllowanceFromZeroAddress() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("ERC20: decreased allowance below zero"));
        ERC20Extended.decrease_allowance(vm.addr(1), type(uint256).max);
    }

    function testBurnSuccessCase1() public {
        address owner = address(vyperDeployer);
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        uint256 amount = 0;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);
        ERC20Extended.burn(amount);
        assertTrue(ERC20Extended.balanceOf(owner) == balance - amount);
        assertTrue(ERC20Extended.totalSupply() == totalSupply - amount);
        vm.stopPrank();
    }

    function testBurnSuccessCase2() public {
        address owner = address(vyperDeployer);
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        uint256 amount = 100;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);
        ERC20Extended.burn(amount);
        assertTrue(ERC20Extended.balanceOf(owner) == balance - amount);
        assertTrue(ERC20Extended.totalSupply() == totalSupply - amount);
        vm.stopPrank();
    }

    function testBurnInvalidAmount() public {
        address owner = address(vyperDeployer);
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 amount = balance + 1;
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        ERC20Extended.burn(amount);
    }

    function testBurnFromZeroAddress() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("ERC20: burn from the zero address"));
        ERC20Extended.burn(0);
    }

    function testBurnFromSuccessCase1() public {
        address owner = address(vyperDeployer);
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        address spender = vm.addr(1);
        uint256 amount = 0;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(
            owner,
            spender,
            ERC20Extended.allowance(owner, spender) - amount
        );
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);
        ERC20Extended.burn_from(owner, amount);
        assertTrue(ERC20Extended.balanceOf(owner) == balance - amount);
        assertTrue(ERC20Extended.totalSupply() == totalSupply - amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == 0);
        vm.stopPrank();
    }

    function testBurnFromSuccessCase2() public {
        address owner = address(vyperDeployer);
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        address spender = vm.addr(1);
        uint256 amount = 100;
        vm.prank(owner);
        ERC20Extended.approve(spender, balance);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(
            owner,
            spender,
            ERC20Extended.allowance(owner, spender) - amount
        );
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);
        ERC20Extended.burn_from(owner, amount);
        assertTrue(ERC20Extended.balanceOf(owner) == balance - amount);
        assertTrue(ERC20Extended.totalSupply() == totalSupply - amount);
        assertTrue(ERC20Extended.allowance(owner, spender) == balance - amount);
        vm.stopPrank();
    }

    function testBurnFromExceedingBalance() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.startPrank(spender);
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        ERC20Extended.burn_from(owner, amount);
    }

    function testBurnFromInsufficientAllowanceCase1() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.burn_from(owner, amount);
    }

    function testBurnFromInsufficientAllowanceCase2() public {
        address owner = address(vyperDeployer);
        address spender = vm.addr(1);
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.burn_from(owner, amount);
    }

    function testBurnFromUnlimitedAllowance() public {
        address owner = address(vyperDeployer);
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        address spender = vm.addr(1);
        uint256 amount = balance;
        vm.prank(owner);
        ERC20Extended.approve(spender, type(uint256).max);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);
        ERC20Extended.burn_from(owner, amount);
        assertTrue(ERC20Extended.balanceOf(owner) == balance - amount);
        assertTrue(ERC20Extended.totalSupply() == totalSupply - amount);
        assertTrue(
            ERC20Extended.allowance(owner, spender) == type(uint256).max
        );
        vm.stopPrank();
    }

    function testBurnFromFromZeroAddress() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("ERC20: approve to the zero address"));
        ERC20Extended.burn_from(vm.addr(1), 0);
    }

    function testMintSuccess() public {
        address minter = address(vyperDeployer);
        address owner = vm.addr(1);
        uint256 amount = type(uint8).max;
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
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
        vm.stopPrank();
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

    function testPermitSuccess() public {
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
        assertEq(ERC20Extended.allowance(owner, spender), amount);
        assertEq(ERC20Extended.nonces(owner), 1);
    }

    function testPermitReplaySignature() public {
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitOtherSignature() public {
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            3,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitBadChainId() public {
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid + 1,
                address(ERC20Extended)
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitBadNonce() public {
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 amount = 100;
        uint256 nonce = 1;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitExpiredDeadline() public {
        address owner = vm.addr(1);
        address spender = vm.addr(2);
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp - 1;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: expired deadline"));
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testCachedDomainSeparator() public {
        assertEq(ERC20Extended.DOMAIN_SEPARATOR(), _CACHED_DOMAIN_SEPARATOR);
    }

    function testDomainSeparator() public {
        vm.chainId(block.chainid + 1);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                address(ERC20Extended)
            )
        );
        assertEq(ERC20Extended.DOMAIN_SEPARATOR(), digest);
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
