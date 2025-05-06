// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreate2} from "./interfaces/ICreate2.sol";

contract Create2Test is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICreate2 private create2;

    address private create2Addr;

    function setUp() public {
        create2 = ICreate2(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "create2_mock"));
        create2Addr = address(create2);
    }

    function testComputeCreate2Address() public {
        bytes32 salt = keccak256("WAGMI");
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(type(ERC20Mock).creationCode, args);
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2.compute_create2_address(salt, bytecodeHash, address(this));

        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(arg1, arg2, arg3, arg4);
        assertEq(create2AddressComputed, vm.computeCreate2Address(salt, bytecodeHash, address(this)));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }

    function testComputeCreate2AddressSelf() public {
        bytes32 salt = keccak256("WAGMI");
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(type(ERC20Mock).creationCode, args);
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2.compute_create2_address_self(salt, bytecodeHash);

        vm.startPrank(create2Addr);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(create2AddressComputed, vm.computeCreate2Address(salt, bytecodeHash, create2Addr));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }

    function testFuzzComputeCreate2Address(bytes32 salt, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(type(ERC20Mock).creationCode, args);
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2.compute_create2_address(salt, bytecodeHash, deployer);

        vm.startPrank(deployer);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(create2AddressComputed, vm.computeCreate2Address(salt, bytecodeHash, deployer));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }

    function testFuzzComputeCreate2AddressSelf(bytes32 salt) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(type(ERC20Mock).creationCode, args);
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2.compute_create2_address_self(salt, bytecodeHash);

        vm.startPrank(create2Addr);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(create2AddressComputed, vm.computeCreate2Address(salt, bytecodeHash, create2Addr));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }
}
