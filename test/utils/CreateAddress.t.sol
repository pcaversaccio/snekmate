// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";
import {ERC20Mock} from "../../lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {Create} from "../../lib/create-util/contracts/Create.sol";

import {ICreateAddress} from "../../test/utils/interfaces/ICreateAddress.sol";

contract CreateAddressTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    Create private create = new Create();
    ICreateAddress private createAddress;

    function setUp() public {
        createAddress = ICreateAddress(
            vyperDeployer.deployContract("src/utils/", "CreateAddress")
        );
    }

    function testComputeAddressNonce0x00() public {
        address alice = vm.addr(1);
        uint64 nonce = 0x00;
        address createAddressComputed = createAddress.compute_address_rlp(
            alice,
            nonce
        );
        address createAddressComputedOnChain = create.computeAddress(
            alice,
            nonce
        );
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeAddressNonce0x7f() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        uint64 nonce = 0x7f;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(create),
            nonce
        );
        address createAddressComputedOnChain = create.deploy(0, bytecode);
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeAddressNonceUint8() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        uint64 nonce = type(uint8).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(create),
            nonce
        );
        address createAddressComputedOnChain = create.deploy(0, bytecode);
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeAddressNonceUint16() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        uint64 nonce = type(uint16).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(create),
            nonce
        );
        address createAddressComputedOnChain = create.deploy(0, bytecode);
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeAddressNonceUint24() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        uint64 nonce = type(uint24).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(create),
            nonce
        );
        address createAddressComputedOnChain = create.deploy(0, bytecode);
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeAddressNonceUint32() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        bytes memory args = abi.encode(arg1, arg2, arg3, arg4);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC20Mock.sol:ERC20Mock"),
            args
        );
        uint64 nonce = type(uint32).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(create),
            nonce
        );
        address createAddressComputedOnChain = create.deploy(0, bytecode);
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeSelfAddressNonce0x7f() public {
        uint64 nonce = 0x7f;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressComputedOnChain = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeSelfAddressNonceUint8() public {
        uint64 nonce = type(uint8).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressComputedOnChain = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeSelfAddressNonceUint16() public {
        uint64 nonce = type(uint16).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressComputedOnChain = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeSelfAddressNonceUint24() public {
        uint64 nonce = type(uint24).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressComputedOnChain = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }

    function testComputeSelfAddressNonceUint32() public {
        uint64 nonce = type(uint32).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressComputedOnChain = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressComputedOnChain);
    }
}
