// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IBlockHash} from "./interfaces/IBlockHash.sol";

contract BlockHashTest is Test {
    address private constant HISTORY_STORAGE_ADDRESS =
        0x0000F90827F1C53a10cb7A02335B175320002935;
    bytes private constant HISTORY_STORAGE_RUNTIME_BYTECODE =
        hex"3373fffffffffffffffffffffffffffffffffffffffe14604657602036036042575f35600143038111604257611fff81430311604257611fff9006545f5260205ff35b5f5ffd5b5f35611fff60014303065500";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    IBlockHash private blockHash;

    address private blockHashAddr;

    function setUp() public {
        blockHash = IBlockHash(
            vyperDeployer.deployContract(
                "src/snekmate/utils/mocks/",
                "blockhash_mock"
            )
        );
        blockHashAddr = address(blockHash);
        vm.etch(HISTORY_STORAGE_ADDRESS, HISTORY_STORAGE_RUNTIME_BYTECODE);
    }
}
