// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {Create} from "create-util/Create.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreateAddress} from "./interfaces/ICreateAddress.sol";

contract CreateAddressTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    Create private create = new Create();

    ICreateAddress private createAddress;

    function setUp() public {
        createAddress = ICreateAddress(
            vyperDeployer.deployContract("src/utils/", "CreateAddress")
        );
    }

    function testComputeAddressRevertTooHighNonce() public {
        uint72 nonce = uint72(type(uint64).max);
        vm.expectRevert(bytes("RLP: invalid nonce value"));
        createAddress.compute_address_rlp(vm.addr(1), nonce);
    }

    function testComputeAddressSelfRevertTooHighNonce() public {
        uint72 nonce = uint72(type(uint64).max);
        vm.expectRevert(bytes("RLP: invalid nonce value"));
        createAddress.compute_address_rlp_self(nonce);
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
        uint64 nonce = 0x7f;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint8() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = type(uint8).max;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint16() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = type(uint16).max;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint24() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = type(uint24).max;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint32() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = type(uint32).max;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint40() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = type(uint40).max;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint48() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = type(uint48).max;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint56() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = type(uint56).max;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressNonceUint64() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = vm.addr(1);
        uint256 arg4 = 100;
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(address(this), nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            address(this),
            nonce
        );
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonce0x7f() public {
        uint64 nonce = 0x7f;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint8() public {
        uint64 nonce = type(uint8).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint16() public {
        uint64 nonce = type(uint16).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint24() public {
        uint64 nonce = type(uint24).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint32() public {
        uint64 nonce = type(uint32).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint40() public {
        uint64 nonce = type(uint40).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint48() public {
        uint64 nonce = type(uint48).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint56() public {
        uint64 nonce = type(uint40).max;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }

    function testComputeAddressSelfNonceUint64() public {
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(address(create), nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            address(createAddress),
            nonce
        );
        assertEq(createAddressComputed, createAddressLibComputed);
    }
}
