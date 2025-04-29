// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IBlockHash} from "./interfaces/IBlockHash.sol";

contract BlockHashTest is Test {
    /**
     * @dev For the specifications of EIP-2935, see here: https://eips.ethereum.org/EIPS/eip-2935.
     */
    address private constant _SYSTEM_ADDRESS =
        0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
    address private constant _HISTORY_STORAGE_ADDRESS =
        0x0000F90827F1C53a10cb7A02335B175320002935;
    bytes private constant _HISTORY_STORAGE_RUNTIME_BYTECODE =
        hex"3373fffffffffffffffffffffffffffffffffffffffe14604657602036036042575f35600143038111604257611fff81430311604257611fff9006545f5260205ff35b5f5ffd5b5f35611fff60014303065500";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBlockHash private blockHash;

    function setUp() public {
        blockHash = IBlockHash(
            vyperDeployer.deployContract(
                "src/snekmate/utils/mocks/",
                "block_hash_mock"
            )
        );
        vm.etch(_HISTORY_STORAGE_ADDRESS, _HISTORY_STORAGE_RUNTIME_BYTECODE);
    }

    function testBlockHashCurrentAndFutureBlock() public view {
        assertEq(blockHash.block_hash(vm.getBlockNumber()), bytes32(0));
        assertEq(
            blockHash.block_hash(vm.getBlockNumber()),
            blockhash(vm.getBlockNumber())
        );
        assertEq(blockHash.block_hash(vm.getBlockNumber() + 1), bytes32(0));
        assertEq(
            blockHash.block_hash(vm.getBlockNumber() + 1),
            blockhash(vm.getBlockNumber() + 1)
        );
    }

    function testBlockHashWithin256Range() public {
        bytes32 hash = keccak256("Long Live Vyper!");
        vm.roll(1_337);
        uint256 blockNumber = vm.getBlockNumber() - 256;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), hash);
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testBlockHashAbove8191Range() public {
        bytes32 hash = keccak256("Long Live Vyper!");
        vm.roll(31_337);
        uint256 blockNumber = vm.getBlockNumber() - 8192;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), bytes32(0));
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testBlockHashHistoryContractNotDeployed() public {
        /**
         * @dev First, ensure that the logic behaves as expected when the
         * history contract is deployed.
         */
        bytes32 hash = keccak256("Long Live Vyper!");
        uint256 blockNumber1 = 1_337;
        vm.roll(blockNumber1 + 1);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success1, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        vm.stopPrank();
        assertTrue(success1);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((vm.getBlockNumber() - 1) % 8191)
            ),
            hash
        );
        vm.roll(blockNumber1 + 5_000);
        assertEq(blockHash.block_hash(blockNumber1), hash);

        /**
         * @dev Second, ensure the fallback logic works properly when the
         * history contract is not deployed.
         */
        vm.etch(_HISTORY_STORAGE_ADDRESS, type(VyperDeployer).runtimeCode);
        uint256 blockNumber2 = 31_337;
        vm.roll(blockNumber2 + 1);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success2, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        vm.stopPrank();
        assertTrue(!success2);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((vm.getBlockNumber() - 1) % 8191)
            ),
            bytes32(0)
        );
        vm.roll(blockNumber2 + 5_000);
        assertEq(blockHash.block_hash(blockNumber2), bytes32(0));
    }

    function testBlockHashWithin257And8191Range() public {
        bytes32 hash = keccak256("Long Live Vyper!");
        uint256 blockNumber = 31_337;
        vm.roll(blockNumber + 1);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        vm.stopPrank();
        assertTrue(success);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((vm.getBlockNumber() - 1) % 8191)
            ),
            hash
        );
        vm.roll(blockNumber + 1_337);
        assertEq(blockHash.block_hash(blockNumber), hash);
    }

    function testFuzzBlockHashCurrentAndFutureBlock(
        uint256 blockNumber
    ) public view {
        blockNumber = bound(
            blockNumber,
            vm.getBlockNumber(),
            type(uint256).max - 1
        );
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
        /**
         * @dev We use `uint64` here due to Revm's internal saturation of `block.number`
         * to `u64::MAX` (https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L144).
         * If `requested_number >= block_number` (after saturation), Revm returns `U256::ZERO`
         * early without querying the database (https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L148-L157).
         */
        currentBlock = bound(currentBlock, delta, type(uint64).max);
        vm.roll(currentBlock);
        uint256 blockNumber = vm.getBlockNumber() - delta;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), hash);
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testFuzzBlockHashAbove8191Range(
        uint256 currentBlock,
        uint256 delta,
        bytes32 hash
    ) public {
        /**
         * @dev We use `uint64` here due to Revm's internal saturation of `block.number`
         * to `u64::MAX` (https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L144).
         * If `requested_number >= block_number` (after saturation), Revm returns `U256::ZERO`
         * early without querying the database (https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L148-L157).
         */
        delta = bound(delta, 8192, type(uint64).max);
        currentBlock = bound(currentBlock, delta, type(uint64).max);
        vm.roll(currentBlock);
        uint256 blockNumber = vm.getBlockNumber() - delta;
        vm.setBlockhash(blockNumber, hash);
        assertEq(blockHash.block_hash(blockNumber), bytes32(0));
        assertEq(blockHash.block_hash(blockNumber), blockhash(blockNumber));
    }

    function testFuzzBlockHashHistoryContractNotDeployed(
        uint256 currentBlock,
        uint256 delta,
        bytes32 hash
    ) public {
        delta = bound(delta, 257, type(uint56).max);
        /**
         * @dev We use `type(uint56).max` to prevent an overflow, as Revm internally saturates `block.number`
         * to `u64::MAX` (see: https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L144).
         * Since the `currentBlock` is incremented by `delta` at the end of the test, using `type(uint64).max`
         * would result in an overflow. If `requested_number >= block_number` (after saturation), Revm returns `U256::ZERO`
         * early without querying the database (https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L148-L157).
         */
        currentBlock = bound(currentBlock, delta, type(uint56).max);
        vm.etch(_HISTORY_STORAGE_ADDRESS, type(VyperDeployer).runtimeCode);
        vm.roll(currentBlock + 1);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        vm.stopPrank();
        assertTrue(!success);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((vm.getBlockNumber() - 1) % 8191)
            ),
            bytes32(0)
        );
        vm.roll(currentBlock + delta);
        assertEq(blockHash.block_hash(currentBlock), bytes32(0));
    }

    function testFuzzBlockHashWithin257And8191Range(
        uint256 currentBlock,
        uint256 delta,
        bytes32 hash
    ) public {
        delta = bound(delta, 257, 8191);
        /**
         * @dev We use `type(uint56).max` to prevent an overflow, as Revm internally saturates `block.number`
         * to `u64::MAX` (see: https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L144).
         * Since the `currentBlock` is incremented by `delta` at the end of the test, using `type(uint64).max`
         * would result in an overflow. If `requested_number >= block_number` (after saturation), Revm returns `U256::ZERO`
         * early without querying the database (https://github.com/bluealloy/revm/blob/b2c789d42d4eee93ce111f1a7d3d0708f1e34180/crates/interpreter/src/instructions/host.rs#L148-L157).
         */
        currentBlock = bound(currentBlock, delta, type(uint56).max);
        vm.roll(currentBlock + 1);
        vm.startPrank(_SYSTEM_ADDRESS);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _HISTORY_STORAGE_ADDRESS.call(abi.encode(hash));
        vm.stopPrank();
        assertTrue(success);
        assertEq(
            vm.load(
                _HISTORY_STORAGE_ADDRESS,
                bytes32((vm.getBlockNumber() - 1) % 8191)
            ),
            hash
        );
        vm.roll(currentBlock + delta);
        assertEq(blockHash.block_hash(currentBlock), hash);
    }
}
