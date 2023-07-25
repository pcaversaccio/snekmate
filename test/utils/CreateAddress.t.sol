// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {Create} from "create-util/Create.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreateAddress} from "./interfaces/ICreateAddress.sol";

contract CreateAddressTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    Create private create = new Create();

    ICreateAddress private createAddress;

    address private createAddr = address(create);
    address private self = address(this);
    address private createAddressAddr;

    function setUp() public {
        createAddress = ICreateAddress(
            vyperDeployer.deployContract("src/utils/", "CreateAddress")
        );
        createAddressAddr = address(createAddress);
    }

    function testComputeAddressRevertTooHighNonce() public {
        uint72 nonce = uint72(type(uint64).max);
        vm.expectRevert(bytes("RLP: invalid nonce value"));
        createAddress.compute_address_rlp(makeAddr("alice"), nonce);
    }

    function testComputeAddressSelfRevertTooHighNonce() public {
        uint72 nonce = uint72(type(uint64).max);
        vm.expectRevert(bytes("RLP: invalid nonce value"));
        createAddress.compute_address_rlp_self(nonce);
    }

    function testComputeAddressNonce0x00() public {
        address alice = makeAddr("alice");
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = 0x7f;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint8).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint16).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint24).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint32).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint40).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint48).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint56).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(self, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            self,
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
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = 0x7f;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint8() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint8).max;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint16() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint16).max;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint24() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint24).max;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint32() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint32).max;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint40() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint40).max;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint48() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint48).max;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint56() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = type(uint56).max;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeAddressSelfNonceUint64() public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressRevertTooHighNonce(
        uint256 nonce,
        address deployer
    ) public {
        nonce = bound(
            nonce,
            uint256(type(uint64).max),
            uint256(type(uint256).max)
        );
        vm.expectRevert(bytes("RLP: invalid nonce value"));
        createAddress.compute_address_rlp(deployer, nonce);
    }

    function testFuzzComputeAddressSelfRevertTooHighNonce(
        uint256 nonce
    ) public {
        nonce = bound(
            nonce,
            uint256(type(uint64).max),
            uint256(type(uint256).max)
        );
        vm.expectRevert(bytes("RLP: invalid nonce value"));
        createAddress.compute_address_rlp_self(nonce);
    }

    function testFuzzComputeAddressNonce0x7f(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(uint256(nonce), vm.getNonce(deployer) + 1, 0x7f));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint8(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(nonce, 0x7f + 1, uint256(type(uint8).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint16(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(nonce, uint64(type(uint8).max) + 1, uint64(type(uint16).max))
        );
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint24(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint16).max) + 1,
                uint256(type(uint24).max)
            )
        );
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint32(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint24).max) + 1,
                uint256(type(uint32).max)
            )
        );
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint40(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint32).max) + 1,
                uint256(type(uint40).max)
            )
        );
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint48(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint40).max) + 1,
                uint256(type(uint48).max)
            )
        );
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint56(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint48).max) + 1,
                uint256(type(uint56).max)
            )
        );
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressNonceUint64(
        uint64 nonce,
        address deployer
    ) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint56).max) + 1,
                uint256(type(uint64).max) - 1
            )
        );
        vm.setNonce(deployer, nonce);
        address createAddressComputed = createAddress.compute_address_rlp(
            deployer,
            nonce
        );

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonce0x7f(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(bound(nonce, vm.getNonce(createAddressAddr) + 1, 0x7f));
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint8(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(uint256(nonce), 0x7f + 1, uint256(type(uint8).max))
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint16(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint8).max) + 1,
                uint256(type(uint16).max)
            )
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint24(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint16).max) + 1,
                uint256(type(uint24).max)
            )
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint32(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint24).max) + 1,
                uint256(type(uint32).max)
            )
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint40(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint32).max) + 1,
                uint256(type(uint40).max)
            )
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint48(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint40).max) + 1,
                uint256(type(uint48).max)
            )
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint56(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint48).max) + 1,
                uint256(type(uint56).max)
            )
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeAddressSelfNonceUint64(uint64 nonce) public {
        string memory arg1 = "MyToken";
        string memory arg2 = "MTKN";
        address arg3 = makeAddr("initialAccount");
        uint256 arg4 = 100;
        nonce = uint64(
            bound(
                uint256(nonce),
                uint256(type(uint56).max) + 1,
                uint256(type(uint64).max) - 1
            )
        );
        vm.setNonce(createAddressAddr, nonce);
        address createAddressComputed = createAddress.compute_address_rlp_self(
            nonce
        );
        address createAddressLibComputed = create.computeAddress(
            createAddressAddr,
            nonce
        );

        vm.prank(createAddressAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(
            arg1,
            arg2,
            arg3,
            arg4
        );
        assertEq(createAddressComputed, createAddressLibComputed);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }
}
