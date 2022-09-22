// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {EtherReceiver} from "./mocks/EtherReceiver.sol";
import {MockCallee, Reverted} from "./mocks/MockCallee.sol";
import {MulticallTokenMock} from "../../lib/openzeppelin-contracts/contracts/mocks/MulticallTokenMock.sol";
import {MulticallTest} from "../../lib/openzeppelin-contracts/contracts/mocks/MulticallTest.sol";

import {IMulticall} from "../../test/utils/interfaces/IMulticall.sol";

contract MulticallsTest is Test {
    uint256 private constant _AMOUNT = 25000;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IMulticall private multicall;
    EtherReceiver private etherReceiver;
    MockCallee private mockCallee;
    MulticallTokenMock private multicallTokenMock;

    function setUp() public {
        multicall = IMulticall(
            vyperDeployer.deployContract("src/utils/", "Multicall")
        );
        etherReceiver = new EtherReceiver();
        mockCallee = new MockCallee();
        multicallTokenMock = new MulticallTokenMock(_AMOUNT);
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
            true,
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
            true,
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
            true,
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
            true,
            0,
            abi.encodeWithSignature("store(uint256)", type(uint256).max)
        );
        batchValue[2] = IMulticall.BatchValue(
            address(mockCallee),
            false,
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
        vm.expectRevert(
            abi.encodeWithSelector(Reverted.selector, address(mockCallee))
        );
        multicall.multicall_value(batchValue);
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
            true,
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
        multicall.multicall_value(batchValue);
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
