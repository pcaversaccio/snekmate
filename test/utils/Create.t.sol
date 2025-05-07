// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreate} from "./interfaces/ICreate.sol";

contract CreateTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICreate private create;

    address private self = address(this);
    address private createAddr;

    function setUp() public {
        create = ICreate(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "create_mock"));
        createAddr = address(create);
    }

    function testComputeCreateAddressRevertTooHighNonce() public {
        uint72 nonce = uint72(type(uint64).max);
        vm.expectRevert(bytes("create: invalid nonce value"));
        create.compute_create_address(makeAddr("alice"), nonce);
    }

    function testComputeCreateAddressSelfRevertTooHighNonce() public {
        uint72 nonce = uint72(type(uint64).max);
        vm.expectRevert(bytes("create: invalid nonce value"));
        create.compute_create_address_self(nonce);
    }

    function testComputeCreateAddressNonce0x00() public {
        address alice = makeAddr("alice");
        uint64 nonce = 0x00;
        address createAddressComputed = create.compute_create_address(alice, nonce);
        assertEq(createAddressComputed, vm.computeCreateAddress(alice, nonce));
    }

    function testComputeCreateAddressNonce0x7f() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = 0x7f;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint8() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint8).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint16() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint16).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint24() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint24).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint32() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint32).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint40() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint40).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint48() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint48).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint56() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint56).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint64() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonce0x7f() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = 0x7f;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint8() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint8).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint16() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint16).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint24() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint24).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint32() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint32).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint40() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint40).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint48() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint48).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint56() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint56).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint64() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressRevertTooHighNonce(uint256 nonce, address deployer) public {
        nonce = bound(nonce, uint256(type(uint64).max), uint256(type(uint256).max));
        vm.expectRevert(bytes("create: invalid nonce value"));
        create.compute_create_address(deployer, nonce);
    }

    function testFuzzComputeCreateAddressSelfRevertTooHighNonce(uint256 nonce) public {
        nonce = bound(nonce, uint256(type(uint64).max), uint256(type(uint256).max));
        vm.expectRevert(bytes("create: invalid nonce value"));
        create.compute_create_address_self(nonce);
    }

    function testFuzzComputeCreateAddressNonce0x7f(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), vm.getNonce(deployer) + 1, 0x7f));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint8(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(nonce, 0x7f + 1, uint256(type(uint8).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint16(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(nonce, uint64(type(uint8).max) + 1, uint64(type(uint16).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint24(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint16).max) + 1, uint256(type(uint24).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint32(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint24).max) + 1, uint256(type(uint32).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint40(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint32).max) + 1, uint256(type(uint40).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint48(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint40).max) + 1, uint256(type(uint48).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint56(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint48).max) + 1, uint256(type(uint56).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint64(uint64 nonce, address deployer) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint56).max) + 1, uint256(type(uint64).max) - 1));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonce0x7f(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(nonce, vm.getNonce(createAddr) + 1, 0x7f));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint8(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), 0x7f + 1, uint256(type(uint8).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint16(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint8).max) + 1, uint256(type(uint16).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint24(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint16).max) + 1, uint256(type(uint24).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint32(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint24).max) + 1, uint256(type(uint32).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint40(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint32).max) + 1, uint256(type(uint40).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint48(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint40).max) + 1, uint256(type(uint48).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint56(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint48).max) + 1, uint256(type(uint56).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint64(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), uint256(type(uint56).max) + 1, uint256(type(uint64).max) - 1));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(arg1, arg2, arg3, arg4);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }
}
