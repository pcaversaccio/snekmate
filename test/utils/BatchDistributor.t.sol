// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {IBatchDistributor} from "./interfaces/IBatchDistributor.sol";

contract BatchDistributorTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBatchDistributor private batchDistributor;

    function setUp() public {
        batchDistributor = IBatchDistributor(
            vyperDeployer.deployContract("src/utils/", "BatchDistributor")
        );
    }

    function testDistributeEtherOneAddressSuccess() public {
        address payable alice = payable(vm.addr(1));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](1);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 2 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        batchDistributor.distribute_ether{value: 2 wei}(batch);
        assertTrue(alice.balance == 2 wei);
    }

    function testDistributeEtherMultipleAddressesSuccess() public {
        address payable alice = payable(vm.addr(1));
        address payable bob = payable(vm.addr(2));
        address payable carol = payable(vm.addr(3));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 2 wei
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 100 wei
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 2000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        batchDistributor.distribute_ether{value: 2102 wei}(batch);
        assertTrue(alice.balance == 2 wei);
        assertTrue(bob.balance == 100 wei);
        assertTrue(carol.balance == 2000 wei);
    }

    function testDistributeEtherSendsBackExcessiveEther() public {
        address payable alice = payable(vm.addr(1));
        address payable bob = payable(vm.addr(2));
        address payable carol = payable(vm.addr(3));
        address payable msgSender = payable(address(vm.addr(4)));
        vm.deal(msgSender, 1 ether);
        uint256 balance = msgSender.balance;
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 2 wei
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 100 wei
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 2000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        vm.prank(msgSender);
        batchDistributor.distribute_ether{value: 1 ether}(batch);
        assertTrue(alice.balance == 2 wei);
        assertTrue(bob.balance == 100 wei);
        assertTrue(carol.balance == 2000 wei);
        assertTrue(msgSender.balance == (balance - 2 wei - 100 wei - 2000 wei));
    }

    function testDistributeEtherRevertWithNoFallbackFunctionForReceipt()
        public
    {
        address payable alice = payable(address(batchDistributor));
        address payable bob = payable(vm.addr(2));
        address payable carol = payable(vm.addr(3));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 2 wei
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 100 wei
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 2000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        /**
         * @dev The `BatchDistributor` contract does not have a `fallback` function
         * and must revert if funds are sent there.
         */
        vm.expectRevert();
        batchDistributor.distribute_ether{value: 2102 wei}(batch);
    }

    function testDistributeEtherRevertWithNoFallbackFunctionForMsgSender()
        public
    {
        address payable alice = payable(vm.addr(1));
        address payable bob = payable(vm.addr(2));
        address payable carol = payable(vm.addr(3));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 2 wei
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 100 wei
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 2000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        /**
         * @dev The `Test` contract does not have a `fallback` function and must
         * revert if excessive funds are returned.
         */
        vm.expectRevert();
        batchDistributor.distribute_ether{value: 1 ether}(batch);
    }

    function testDistributeEtherRevertWithInsufficientFunds() public {
        address payable alice = payable(vm.addr(1));
        address payable bob = payable(vm.addr(2));
        address payable carol = payable(vm.addr(3));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 2 wei
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 100 wei
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 2000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        /**
         * @dev Sends too little funds, which triggers an insufficient funds error.
         */
        vm.expectRevert();
        batchDistributor.distribute_ether{value: 1 wei}(batch);
    }

    function testDistributeTokenOneAddressSuccess() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(address(batchDistributor), 30);

        address payable alice = payable(vm.addr(2));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](1);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 30
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        batchDistributor.distribute_token(erc20Mock, batch);
        vm.stopPrank();
        assertTrue(erc20Mock.balanceOf(alice) == 30);
    }

    function testDistributeTokenMultipleAddressesSuccess() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(address(batchDistributor), 100);

        address payable alice = payable(vm.addr(2));
        address payable bob = payable(vm.addr(3));
        address payable carol = payable(vm.addr(4));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 30
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 20
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 50
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        batchDistributor.distribute_token(erc20Mock, batch);
        vm.stopPrank();
        assertTrue(erc20Mock.balanceOf(alice) == 30);
        assertTrue(erc20Mock.balanceOf(bob) == 20);
        assertTrue(erc20Mock.balanceOf(carol) == 50);
    }

    function testDistributeTokenRevertWithInsufficientAllowance() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(address(batchDistributor), 99);

        address payable alice = payable(vm.addr(2));
        address payable bob = payable(vm.addr(3));
        address payable carol = payable(vm.addr(4));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 30
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 20
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 50
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        batchDistributor.distribute_token(erc20Mock, batch);
        vm.stopPrank();
    }

    function testDistributeTokenRevertWithInsufficientBalance() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(address(batchDistributor), 120);

        address payable alice = payable(vm.addr(2));
        address payable bob = payable(vm.addr(3));
        address payable carol = payable(vm.addr(4));
        IBatchDistributor.Transaction[]
            memory transaction = new IBatchDistributor.Transaction[](3);
        transaction[0] = IBatchDistributor.Transaction({
            recipient: alice,
            amount: 50
        });
        transaction[1] = IBatchDistributor.Transaction({
            recipient: bob,
            amount: 20
        });
        transaction[2] = IBatchDistributor.Transaction({
            recipient: carol,
            amount: 50
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        batchDistributor.distribute_token(erc20Mock, batch);
        vm.stopPrank();
    }
}
