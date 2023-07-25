// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20Errors} from "openzeppelin/interfaces/draft-IERC6093.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {IBatchDistributor} from "./interfaces/IBatchDistributor.sol";

contract BatchDistributorTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBatchDistributor private batchDistributor;

    address private zeroAddress = address(0);
    address private batchDistributorAddr;

    function setUp() public {
        batchDistributor = IBatchDistributor(
            vyperDeployer.deployContract("src/utils/", "BatchDistributor")
        );
        batchDistributorAddr = address(batchDistributor);
    }

    function testDistributeEtherOneAddressSuccess() public {
        address alice = makeAddr("alice");
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
        assertEq(alice.balance, 2 wei);
        assertEq(batchDistributorAddr.balance, 0);
    }

    function testDistributeEtherMultipleAddressesSuccess() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
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
            amount: 2_000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        batchDistributor.distribute_ether{value: 2_102 wei}(batch);
        assertEq(alice.balance, 2 wei);
        assertEq(bob.balance, 100 wei);
        assertEq(carol.balance, 2_000 wei);
        assertEq(batchDistributorAddr.balance, 0);
    }

    function testDistributeEtherSendsBackExcessiveEther() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
        address msgSender = address(makeAddr("msgSender"));
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
            amount: 2_000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        vm.prank(msgSender);
        batchDistributor.distribute_ether{value: 1 ether}(batch);
        assertEq(alice.balance, 2 wei);
        assertEq(bob.balance, 100 wei);
        assertEq(carol.balance, 2_000 wei);
        assertEq(
            msgSender.balance,
            balance - alice.balance - bob.balance - carol.balance
        );
        assertEq(batchDistributorAddr.balance, 0);
    }

    function testDistributeEtherRevertWithNoFallbackFunctionForReceipt()
        public
    {
        address alice = batchDistributorAddr;
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
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
            amount: 2_000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        /**
         * @dev The `BatchDistributor` contract does not have a `fallback` function
         * and must revert if funds are sent there.
         */
        vm.expectRevert();
        batchDistributor.distribute_ether{value: 2_102 wei}(batch);
        assertEq(batchDistributorAddr.balance, 0);
    }

    function testDistributeEtherRevertWithNoFallbackFunctionForMsgSender()
        public
    {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
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
            amount: 2_000 wei
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
        assertEq(batchDistributorAddr.balance, 0);
    }

    function testDistributeEtherRevertWithInsufficientFunds() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
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
            amount: 2_000 wei
        });
        IBatchDistributor.Batch memory batch = IBatchDistributor.Batch({
            txns: transaction
        });

        /**
         * @dev Sends too little funds, which triggers an insufficient funds error.
         */
        vm.expectRevert();
        batchDistributor.distribute_ether{value: 1 wei}(batch);
        assertEq(batchDistributorAddr.balance, 0);
    }

    function testDistributeTokenOneAddressSuccess() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(batchDistributorAddr, 30);

        address alice = makeAddr("alice");
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
        assertEq(erc20Mock.balanceOf(alice), 30);
        assertEq(erc20Mock.balanceOf(batchDistributorAddr), 0);
    }

    function testDistributeTokenMultipleAddressesSuccess() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(batchDistributorAddr, 100);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
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
        assertEq(erc20Mock.balanceOf(alice), 30);
        assertEq(erc20Mock.balanceOf(bob), 20);
        assertEq(erc20Mock.balanceOf(carol), 50);
        assertEq(erc20Mock.balanceOf(batchDistributorAddr), 0);
    }

    function testDistributeTokenRevertWithInsufficientAllowance() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(batchDistributorAddr, 99);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
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

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                batchDistributorAddr,
                99,
                100
            )
        );
        batchDistributor.distribute_token(erc20Mock, batch);
        assertEq(erc20Mock.balanceOf(batchDistributorAddr), 0);
        vm.stopPrank();
    }

    function testDistributeTokenRevertWithInsufficientBalance() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        ERC20Mock erc20Mock = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.startPrank(arg3);
        erc20Mock.approve(batchDistributorAddr, 120);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
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

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                arg3,
                100,
                120
            )
        );
        batchDistributor.distribute_token(erc20Mock, batch);
        assertEq(erc20Mock.balanceOf(batchDistributorAddr), 0);
        vm.stopPrank();
    }

    function testFuzzDistributeEtherMultipleAddressesSuccess(
        IBatchDistributor.Batch memory batch,
        uint256 value
    ) public {
        value = bound(value, type(uint16).max, type(uint32).max);
        vm.assume(batch.txns.length <= 50);
        for (uint256 i; i < batch.txns.length; ++i) {
            batch.txns[i].amount = bound(batch.txns[i].amount, 1, 100);
            assumePayable(batch.txns[i].recipient);
        }

        uint256 valueAccumulator;
        address msgSender = address(makeAddr("msgSender"));
        vm.deal(msgSender, value);
        vm.prank(msgSender);
        batchDistributor.distribute_ether{value: value}(batch);
        for (uint256 i; i < batch.txns.length; ++i) {
            valueAccumulator += batch.txns[i].amount;
            assertGe(batch.txns[i].recipient.balance, batch.txns[i].amount);
        }
        assertGe(msgSender.balance, value - valueAccumulator);
        assertEq(batchDistributorAddr.balance, 0);
    }

    function testFuzzDistributeTokenMultipleAddressesSuccess(
        IBatchDistributor.Batch memory batch,
        address initialAccount,
        uint256 initialAmount
    ) public {
        vm.assume(
            initialAccount != zeroAddress &&
                initialAccount != batchDistributorAddr
        );
        initialAmount = bound(
            initialAmount,
            type(uint16).max,
            type(uint32).max
        );
        vm.assume(batch.txns.length <= 50);
        for (uint256 i; i < batch.txns.length; ++i) {
            batch.txns[i].amount = bound(batch.txns[i].amount, 1, 100);
            vm.assume(
                batch.txns[i].recipient != batchDistributorAddr &&
                    batch.txns[i].recipient != zeroAddress
            );
        }

        uint256 valueAccumulator;
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        ERC20Mock erc20Mock = new ERC20Mock(
            arg1,
            arg2,
            initialAccount,
            initialAmount
        );
        vm.startPrank(initialAccount);
        erc20Mock.approve(batchDistributorAddr, initialAmount);
        batchDistributor.distribute_token(erc20Mock, batch);
        vm.stopPrank();
        for (uint256 i; i < batch.txns.length; ++i) {
            valueAccumulator += batch.txns[i].amount;
            assertGe(
                erc20Mock.balanceOf(batch.txns[i].recipient),
                batch.txns[i].amount
            );
        }
        assertGe(
            erc20Mock.balanceOf(initialAccount),
            initialAmount - valueAccumulator
        );
        assertEq(erc20Mock.balanceOf(batchDistributorAddr), 0);
    }
}

contract BatchDistributorInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBatchDistributor private batchDistributor;
    BatchDistributorHandler private batchDistributorHandler;

    ERC20Mock private erc20Mock;
    address private batchDistributorAddr;

    function setUp() public {
        batchDistributor = IBatchDistributor(
            vyperDeployer.deployContract("src/utils/", "BatchDistributor")
        );
        batchDistributorAddr = address(batchDistributor);
        address msgSender = makeAddr("msgSender");
        erc20Mock = new ERC20Mock(
            "MyToken",
            "MTKN",
            msgSender,
            type(uint256).max
        );
        batchDistributorHandler = new BatchDistributorHandler(
            batchDistributor,
            erc20Mock
        );
        targetContract(address(batchDistributorHandler));
        targetSender(msgSender);
    }

    function invariantNoEtherBalance() public {
        assertEq(batchDistributorAddr.balance, 0);
    }

    function invariantNoTokenBalance() public {
        /**
         * @dev This invariant breaks when tokens are sent directly to `batchDistributor`
         * as part of `distribute_token`. However, this behaviour is acceptable.
         */
        assertEq(erc20Mock.balanceOf(batchDistributorAddr), 0);
    }
}

contract BatchDistributorHandler {
    IBatchDistributor private batchDistributor;
    ERC20Mock private token;

    constructor(IBatchDistributor batchDistributor_, ERC20Mock token_) {
        batchDistributor = batchDistributor_;
        token = token_;
    }

    function distribute_ether(
        IBatchDistributor.Batch calldata batch
    ) public payable {
        batchDistributor.distribute_ether(batch);
    }

    function distribute_token(IBatchDistributor.Batch calldata batch) public {
        token.approve(address(batchDistributor), type(uint256).max);
        batchDistributor.distribute_token(token, batch);
    }
}
