// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {Create2Impl} from "./mocks/Create2Impl.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreate2Address} from "./interfaces/ICreate2Address.sol";

contract Create2AddressTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    Create2Impl private create2Impl = new Create2Impl();

    ICreate2Address private create2Address;

    address private create2AddressAddr;

    function setUp() public {
        create2Address = ICreate2Address(
            vyperDeployer.deployContract("src/utils/", "Create2Address")
        );
        create2AddressAddr = address(create2Address);
    }

    function testComputeAddress() public {
        bytes32 salt = keccak256("WAGMI");
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2Address.compute_address(
            salt,
            bytecodeHash,
            address(this)
        );

        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(
            create2AddressComputed,
            address(create2AddressComputedOnChain)
        );
    }

    function testComputeAddressSelf() public {
        bytes32 salt = keccak256("WAGMI");
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2Address.compute_address_self(
            salt,
            bytecodeHash
        );
        address create2AddressOZComputed = create2Impl
            .computeAddressWithDeployer(salt, bytecodeHash, create2AddressAddr);

        vm.prank(create2AddressAddr);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(create2AddressComputed, create2AddressOZComputed);
        assertEq(
            create2AddressComputed,
            address(create2AddressComputedOnChain)
        );
    }

    function testFuzzComputeAddress(bytes32 salt, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2Address.compute_address(
            salt,
            bytecodeHash,
            deployer
        );

        vm.prank(deployer);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(
            create2AddressComputed,
            address(create2AddressComputedOnChain)
        );
    }

    function testFuzzComputeAddressSelf(bytes32 salt) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        address create2AddressComputed = create2Address.compute_address_self(
            salt,
            bytecodeHash
        );
        address create2AddressOZComputed = create2Impl
            .computeAddressWithDeployer(salt, bytecodeHash, create2AddressAddr);

        vm.prank(create2AddressAddr);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(create2AddressComputed, create2AddressOZComputed);
        assertEq(
            create2AddressComputed,
            address(create2AddressComputedOnChain)
        );
    }
}
