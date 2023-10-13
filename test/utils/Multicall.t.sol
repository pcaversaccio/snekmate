// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {EtherReceiver} from "./mocks/EtherReceiver.sol";
import {MockCallee, Reverted} from "./mocks/MockCallee.sol";

import {IMulticall} from "./interfaces/IMulticall.sol";

contract MulticallTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    EtherReceiver private etherReceiver = new EtherReceiver();
    MockCallee private mockCallee = new MockCallee();

    IMulticall private multicall;

    address private etherReceiverAddr = address(etherReceiver);
    address private mockCalleeAddr = address(mockCallee);

    function setUp() public {
        multicall = IMulticall(
            vyperDeployer.deployContract("src/utils/", "Multicall")
        );
    }

    function testMulticallSuccess() public {
        IMulticall.Batch[] memory batch = new IMulticall.Batch[](3);
        batch[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch[2] = IMulticall.Batch(
            mockCalleeAddr,
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.Result[] memory results = multicall.multicall(batch);
        assertTrue(results[0].success);
        assertEq(
            keccak256(results[0].returnData),
            keccak256(abi.encodePacked(blockhash(block.number)))
        );
        assertEq(
            keccak256(results[1].returnData),
            keccak256(abi.encodePacked(abi.encode(true)))
        );
        assertEq(mockCallee.number(), type(uint256).max);
        assertTrue(!results[2].success);
    }

    function testMulticallRevert() public {
        IMulticall.Batch[] memory batch = new IMulticall.Batch[](3);
        batch[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch[2] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        vm.expectRevert(
            abi.encodeWithSelector(Reverted.selector, mockCalleeAddr)
        );
        multicall.multicall(batch);
    }

    function testMulticallValueSuccess() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batchValue[2] = IMulticall.BatchValue(
            mockCalleeAddr,
            true,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            1,
            abi.encodeWithSignature("transferEther(address)", etherReceiverAddr)
        );

        IMulticall.Result[] memory results = multicall.multicall_value{
            value: 1
        }(batchValue);
        assertTrue(results[0].success);
        assertEq(
            keccak256(results[0].returnData),
            keccak256(abi.encodePacked(blockhash(block.number)))
        );
        assertEq(
            keccak256(results[1].returnData),
            keccak256(abi.encodePacked(abi.encode(true)))
        );
        assertEq(mockCallee.number(), type(uint256).max);
        assertEq(etherReceiverAddr.balance, 1 wei);
        assertTrue(!results[2].success);
        assertTrue(results[3].success);
    }

    function testMulticallValueRevertCase1() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        /**
         * @dev We don't allow for a failure.
         */
        batchValue[2] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            1,
            abi.encodeWithSignature("transferEther(address)", etherReceiverAddr)
        );

        vm.expectRevert(
            abi.encodeWithSelector(Reverted.selector, mockCalleeAddr)
        );
        multicall.multicall_value{value: 1}(batchValue);
    }

    function testMulticallValueRevertCase2() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            mockCalleeAddr,
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batchValue[2] = IMulticall.BatchValue(
            mockCalleeAddr,
            true,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            mockCalleeAddr,
            true,
            1,
            abi.encodeWithSignature("transferEther(address)", etherReceiverAddr)
        );

        vm.expectRevert(bytes("Multicall: value mismatch"));
        /**
         * @dev We don't send any `msg.value`.
         */
        multicall.multicall_value(batchValue);
    }

    function testMulticallSelfSuccess() public {
        IMulticall.Batch[] memory batch1 = new IMulticall.Batch[](3);
        batch1[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch1[1] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch1[2] = IMulticall.Batch(
            mockCalleeAddr,
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.Batch[] memory batch2 = new IMulticall.Batch[](2);
        batch2[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch2[1] = IMulticall.Batch(
            mockCalleeAddr,
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.BatchSelf[] memory batchSelf = new IMulticall.BatchSelf[](2);
        batchSelf[0] = IMulticall.BatchSelf(
            false,
            abi.encodeWithSignature("multicall((address,bool,bytes)[])", batch1)
        );
        batchSelf[1] = IMulticall.BatchSelf(
            false,
            abi.encodeWithSignature(
                "multistaticcall((address,bool,bytes)[])",
                batch2
            )
        );

        IMulticall.Result[] memory results = multicall.multicall_self(
            batchSelf
        );
        assertTrue(results[0].success);
        assertTrue(results[1].success);
        assertEq(mockCallee.number(), type(uint256).max);
    }

    function testMulticallSelfRevert() public {
        IMulticall.Batch[] memory batch1 = new IMulticall.Batch[](3);
        batch1[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch1[1] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch1[2] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.Batch[] memory batch2 = new IMulticall.Batch[](2);
        batch2[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch2[1] = IMulticall.Batch(
            mockCalleeAddr,
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.BatchSelf[] memory batchSelf = new IMulticall.BatchSelf[](2);
        batchSelf[0] = IMulticall.BatchSelf(
            false,
            abi.encodeWithSignature("multicall((address,bool,bytes)[])", batch1)
        );
        batchSelf[1] = IMulticall.BatchSelf(
            false,
            abi.encodeWithSignature(
                "multistaticcall((address,bool,bytes)[])",
                batch2
            )
        );

        vm.expectRevert(
            abi.encodeWithSelector(Reverted.selector, mockCalleeAddr)
        );
        multicall.multicall_self(batchSelf);
    }

    function testMultistaticcallSuccess() public {
        IMulticall.Batch[] memory batch = new IMulticall.Batch[](2);
        batch[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            mockCalleeAddr,
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.Result[] memory results = multicall.multistaticcall(batch);
        assertTrue(results[0].success);
        assertEq(
            keccak256(results[0].returnData),
            keccak256(abi.encodePacked(blockhash(block.number)))
        );
        assertTrue(!results[1].success);
    }

    function testMultistaticcallRevert() public {
        IMulticall.Batch[] memory batch = new IMulticall.Batch[](3);
        batch[0] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            mockCalleeAddr,
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch[2] = IMulticall.Batch(
            mockCalleeAddr,
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        vm.expectRevert();
        multicall.multistaticcall(batch);
    }
}
