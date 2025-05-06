// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreate3} from "./interfaces/ICreate3.sol";

contract Create3Test is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICreate3 private create3;

    address private self = address(this);
    address private create3Addr;

    function setUp() public {
        create3 = ICreate3(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "create3_mock"));
        create3Addr = address(create3);
    }

    function testFuzzComputeCreate3Address(bytes32 salt, address deployer) external {
        // bytes32 salt = keccak256("WAGMI");
        // string memory arg1 = "MyToken";
        // string memory arg2 = "MTKN";
        // address arg3 = makeAddr("initialAccount");
        // uint256 arg4 = 100;
        // address create3AddressComputed = create3.compute_create3_address(salt, address(this));
        // assertEq(create2AddressComputed, vm.computeCreateAddress(create2Addr, 1));
        // assertEq(create3AddressComputed, address(create2AddressComputedOnChain));
    }
}
