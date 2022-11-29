// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {EtherReceiver} from "./mocks/EtherReceiver.sol";
import {MockCallee, Reverted} from "./mocks/MockCallee.sol";

import {IMulticall} from "./interfaces/IMulticall.sol";

contract MulticallsTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IMulticall private multicall;
    EtherReceiver private etherReceiver;
    MockCallee private mockCallee;

    function setUp() public {
        multicall = IMulticall(
            vyperDeployer.deployContract("src/utils/", "Multicall")
        );
        etherReceiver = new EtherReceiver();
        mockCallee = new MockCallee();
    }

    function testMulticallSuccess() public {
        IMulticall.Batch[] memory batch = new IMulticall.Batch[](3);
        batch[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch[2] = IMulticall.Batch(
            address(mockCallee),
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
        assertTrue(mockCallee.number() == type(uint256).max);
        assertTrue(!results[2].success);
    }

    function testMulticallRevert() public {
        IMulticall.Batch[] memory batch = new IMulticall.Batch[](3);
        batch[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch[2] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        vm.expectRevert(
            abi.encodeWithSelector(Reverted.selector, address(mockCallee))
        );
        multicall.multicall(batch);
    }

    function testMulticallValueSuccess() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batchValue[2] = IMulticall.BatchValue(
            address(mockCallee),
            true,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            1,
            abi.encodeWithSignature(
                "transferEther(address)",
                address(etherReceiver)
            )
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
        assertTrue(mockCallee.number() == type(uint256).max);
        assertTrue(!results[2].success);
        assertTrue(results[3].success);
    }

    function testMulticallValueRevertCase1() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        /// @dev We don't allow for a failure.
        batchValue[2] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            1,
            abi.encodeWithSignature(
                "transferEther(address)",
                address(etherReceiver)
            )
        );

        vm.expectRevert(
            abi.encodeWithSelector(Reverted.selector, address(mockCallee))
        );
        multicall.multicall_value{value: 1}(batchValue);
    }

    function testMulticallValueRevertCase2() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batchValue[2] = IMulticall.BatchValue(
            address(mockCallee),
            true,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            address(mockCallee),
            true,
            1,
            abi.encodeWithSignature(
                "transferEther(address)",
                address(etherReceiver)
            )
        );

        vm.expectRevert(bytes("Multicall: value mismatch"));
        /// @dev We don't send any `msg.value`.
        multicall.multicall_value(batchValue);
    }

    function testMulticallSelfSuccess() public {
        IMulticall.Batch[] memory batch1 = new IMulticall.Batch[](3);
        batch1[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch1[1] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch1[2] = IMulticall.Batch(
            address(mockCallee),
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.Batch[] memory batch2 = new IMulticall.Batch[](2);
        batch2[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch2[1] = IMulticall.Batch(
            address(mockCallee),
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
        assertTrue(mockCallee.number() == type(uint256).max);
    }

    function testMulticallSelfRevert() public {
        IMulticall.Batch[] memory batch1 = new IMulticall.Batch[](3);
        batch1[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch1[1] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch1[2] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.Batch[] memory batch2 = new IMulticall.Batch[](2);
        batch2[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch2[1] = IMulticall.Batch(
            address(mockCallee),
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
            abi.encodeWithSelector(Reverted.selector, address(mockCallee))
        );
        multicall.multicall_self(batchSelf);
    }

    function testMulticallValueSelfSuccess() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batchValue[2] = IMulticall.BatchValue(
            address(mockCallee),
            true,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            1,
            abi.encodeWithSignature(
                "transferEther(address)",
                address(etherReceiver)
            )
        );

        IMulticall.Batch[] memory batch = new IMulticall.Batch[](2);
        batch[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            address(mockCallee),
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.BatchValueSelf[]
            memory batchValueSelf = new IMulticall.BatchValueSelf[](2);
        batchValueSelf[0] = IMulticall.BatchValueSelf(
            false,
            1,
            abi.encodeWithSignature(
                "multicall_value((address,bool,uint256,bytes)[])",
                batchValue
            )
        );
        batchValueSelf[1] = IMulticall.BatchValueSelf(
            true,
            0,
            abi.encodeWithSignature(
                "multistaticcall((address,bool,bytes)[])",
                batch
            )
        );

        IMulticall.Result[] memory results = multicall.multicall_value_self{
            value: 1
        }(batchValueSelf);
        assertTrue(results[0].success);
        assertTrue(!results[1].success);
        assertTrue(address(etherReceiver).balance == 1 wei);
    }

    function testMulticallValueSelfCase1() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        /// @dev We don't allow for a failure.
        batchValue[2] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            1,
            abi.encodeWithSignature(
                "transferEther(address)",
                address(etherReceiver)
            )
        );

        IMulticall.Batch[] memory batch = new IMulticall.Batch[](2);
        batch[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            address(mockCallee),
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.BatchValueSelf[]
            memory batchValueSelf = new IMulticall.BatchValueSelf[](2);
        batchValueSelf[0] = IMulticall.BatchValueSelf(
            false,
            1,
            abi.encodeWithSignature(
                "multicall_value((address,bool,uint256,bytes)[])",
                batchValue
            )
        );
        batchValueSelf[1] = IMulticall.BatchValueSelf(
            true,
            0,
            abi.encodeWithSignature(
                "multistaticcall((address,bool,bytes)[])",
                batch
            )
        );

        vm.expectRevert(
            abi.encodeWithSelector(Reverted.selector, address(mockCallee))
        );
        multicall.multicall_value_self{value: 1}(batchValueSelf);
    }

    function testMulticallValueSelfCase2() public {
        IMulticall.BatchValue[] memory batchValue = new IMulticall.BatchValue[](
            4
        );
        batchValue[0] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batchValue[1] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batchValue[2] = IMulticall.BatchValue(
            address(mockCallee),
            true,
            0,
            abi.encodeWithSignature("thisMethodReverts()")
        );
        batchValue[3] = IMulticall.BatchValue(
            address(mockCallee),
            false,
            1,
            abi.encodeWithSignature(
                "transferEther(address)",
                address(etherReceiver)
            )
        );

        IMulticall.Batch[] memory batch = new IMulticall.Batch[](2);
        batch[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            address(mockCallee),
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        IMulticall.BatchValueSelf[]
            memory batchValueSelf = new IMulticall.BatchValueSelf[](2);
        batchValueSelf[0] = IMulticall.BatchValueSelf(
            false,
            1,
            abi.encodeWithSignature(
                "multicall_value((address,bool,uint256,bytes)[])",
                batchValue
            )
        );
        batchValueSelf[1] = IMulticall.BatchValueSelf(
            true,
            0,
            abi.encodeWithSignature(
                "multistaticcall((address,bool,bytes)[])",
                batch
            )
        );

        vm.expectRevert(bytes("Multicall: value mismatch"));
        /// @dev We send too much `msg.value`.
        multicall.multicall_value_self{value: 2}(batchValueSelf);
    }

    function testMultistaticcallSuccess() public {
        IMulticall.Batch[] memory batch = new IMulticall.Batch[](2);
        batch[0] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            address(mockCallee),
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
            address(mockCallee),
            false,
            abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        batch[1] = IMulticall.Batch(
            address(mockCallee),
            false,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batch[2] = IMulticall.Batch(
            address(mockCallee),
            true,
            abi.encodeWithSignature("thisMethodReverts()")
        );

        vm.expectRevert();
        multicall.multistaticcall(batch);
    }
}
