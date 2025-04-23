// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IBlockHash} from "./interfaces/IBlockHash.sol";

contract BlockHashTest is Test {
    address private constant _SYSTEM_ADDRESS =
        0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
    address private constant _HISTORY_STORAGE_ADDRESS =
        0x0000F90827F1C53a10cb7A02335B175320002935;
    bytes private constant _HISTORY_STORAGE_RUNTIME_BYTECODE =
        hex"3373fffffffffffffffffffffffffffffffffffffffe14604657602036036042575f35600143038111604257611fff81430311604257611fff9006545f5260205ff35b5f5ffd5b5f35611fff60014303065500";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBlockHash private blockHash;

    address private blockHashAddr;

    /**
     * @dev An `internal` helper function that stores a predefined hash in the
     * history contract as the block hash for `block.number + 1`.
     * @param hash The 32-byte block hash.
     */
    function setHistoryBlockhash(bytes32 hash) internal {
        vm.roll(block.number + 1);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        vm.stopPrank();
        assertTrue(success);
        vm.roll(block.number - 1);
    }

    function setUp() public {
        blockHash = IBlockHash(
            vyperDeployer.deployContract(
                "src/snekmate/utils/mocks/",
                "block_hash_mock"
            )
        );
        blockHashAddr = address(blockHash);
        vm.etch(_HISTORY_STORAGE_ADDRESS, _HISTORY_STORAGE_RUNTIME_BYTECODE);
    }

    function testBlockHashCurrentAndFutureBlock() public view {
        assertEq(blockHash.block_hash(block.number), bytes32(0));
        assertEq(blockHash.block_hash(block.number), blockhash(block.number));
        assertEq(blockHash.block_hash(block.number + 1), bytes32(0));
        assertEq(
            blockHash.block_hash(block.number + 1),
            blockhash(block.number + 1)
        );
    }

    function testBlockHashWithin256Range() public {
        bytes32 hash = keccak256("blockhash");
        vm.roll(1_337);
        uint256 blockNumber = block.number - 256;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), hash);
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testBlockHashAbove8191Range() public {
        bytes32 hash = keccak256("blockhash");
        vm.roll(31_337);
        uint256 blockNumber = block.number - 8192;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), bytes32(0));
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testBlockHashHistoryContractNotDeployed() public {
        /**
         * @dev First, ensure that the logic behaves as expected when the
         * history contract is deployed.
         */
        bytes32 hash = keccak256("blockhash");
        uint256 blockNumber1 = 1_337;
        vm.roll(blockNumber1 + 1);
        vm.setBlockhash(blockNumber1, hash);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success1, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        assertTrue(success1);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((block.number - 1) % 8191)
            ),
            hash
        );
        vm.stopPrank();
        vm.roll(blockNumber1 + 5_000);
        assertEq(blockHash.block_hash(blockNumber1), hash);

        /**
         * @dev Second, ensure the fallback logic works properly when the
         * history contract is not deployed.
         */
        vm.etch(_HISTORY_STORAGE_ADDRESS, type(VyperDeployer).runtimeCode);
        uint256 blockNumber2 = 31_337;
        vm.roll(blockNumber2 + 1);
        vm.setBlockhash(blockNumber2, hash);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success2, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        assertTrue(!success2);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((block.number - 1) % 8191)
            ),
            bytes32(0)
        );
        vm.stopPrank();
        vm.roll(blockNumber2 + 5_000);
        assertEq(blockHash.block_hash(blockNumber2), bytes32(0));
    }

    function testBlockHashWithin257And8191Range() public {
        bytes32 hash = keccak256("blockhash");
        uint256 blockNumber = 31_337;
        vm.roll(blockNumber + 1);
        vm.setBlockhash(blockNumber, hash);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        assertTrue(success);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((block.number - 1) % 8191)
            ),
            hash
        );
        vm.stopPrank();
        vm.roll(blockNumber + 1_337);
        assertEq(blockHash.block_hash(blockNumber), hash);
    }

    function testFuzzBlockHashCurrentAndFutureBlock(
        uint256 blockNumber
    ) public view {
        blockNumber = bound(blockNumber, block.number, type(uint256).max - 1);
        assertEq(blockHash.block_hash(blockNumber), bytes32(0));
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
        assertEq(blockHash.block_hash(blockNumber + 1), bytes32(0));
        assertEq(
            blockHash.block_hash(blockNumber + 1),
            blockhash(blockNumber + 1)
        );
    }

    function testFuzzBlockHashWithin256Range(
        uint256 currentBlock,
        uint256 delta,
        bytes32 hash
    ) public {
        delta = bound(delta, 1, 256);
        currentBlock = bound(currentBlock, delta, type(uint256).max);
        vm.roll(currentBlock);
        uint256 blockNumber = block.number - delta;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), hash);
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testFuzzBlockHashAbove8191Range(
        uint256 currentBlock,
        uint256 delta,
        bytes32 hash
    ) public {
        delta = bound(delta, 8192, type(uint256).max);
        currentBlock = bound(currentBlock, delta, type(uint256).max);
        vm.roll(currentBlock);
        uint256 blockNumber = block.number - delta;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), bytes32(0));
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testFuzzBlockHashHistoryContractNotDeployed(
        uint256 currentBlock,
        uint256 delta,
        bytes32 hash
    ) public {
        delta = bound(delta, 0, currentBlock);
        currentBlock = bound(currentBlock, delta, currentBlock + delta);
        vm.etch(_HISTORY_STORAGE_ADDRESS, type(VyperDeployer).runtimeCode);
        vm.roll(currentBlock + 1);
        vm.setBlockhash(currentBlock, hash);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        assertTrue(!success);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((block.number - 1) % 8191)
            ),
            bytes32(0)
        );
        vm.stopPrank();
        vm.roll(currentBlock + delta);
        assertEq(blockHash.block_hash(currentBlock), bytes32(0));
    }

    function testFuzzBlockHashWithin257And8191Range(
        uint256 currentBlock,
        uint256 delta,
        bytes32 hash
    ) public {
        delta = bound(delta, 257, 8191 < currentBlock ? 8191 : currentBlock);
        currentBlock = bound(currentBlock, delta, currentBlock + delta);
        vm.roll(currentBlock + 1);
        vm.setBlockhash(currentBlock, hash);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        assertTrue(success);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((block.number - 1) % 8191)
            ),
            hash
        );
        vm.stopPrank();
        vm.roll(currentBlock + delta);
        assertEq(blockHash.block_hash(currentBlock), hash);
    }
}
