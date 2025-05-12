// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreate} from "./interfaces/ICreate.sol";

contract CreateTest is Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "MTKN";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICreate private create;

    address private self = address(this);
    address private zeroAddress = address(0);
    address private createAddr;
    address private initialAccount;
    bytes private cachedInitCode;

    function setUp() public {
        initialAccount = makeAddr("initialAccount");
        bytes memory args = abi.encode(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        cachedInitCode = abi.encodePacked(type(ERC20Mock).creationCode, args);

        create = ICreate(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "create_mock"));
        createAddr = address(create);
    }

    function testDeployCreateSuccess() public {
        address computedAddress = create.compute_create_address(createAddr, 1);
        vm.expectEmit(true, true, false, true, computedAddress);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create.deploy_create(cachedInitCode);
        assertEq(newContract, computedAddress);
        assertNotEq(newContract, zeroAddress);
        assertNotEq(newContract.code.length, 0);
        assertEq(newContract.balance, 0);
        assertEq(createAddr.balance, 0);
        assertEq(ERC20Mock(computedAddress).name(), _NAME);
        assertEq(ERC20Mock(computedAddress).symbol(), _SYMBOL);
        assertEq(ERC20Mock(computedAddress).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testDeployCreateValueSuccess() public {
        uint256 msgValue = 1_337;
        address computedAddress = create.compute_create_address(createAddr, 1);
        vm.expectEmit(true, true, false, true, computedAddress);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create.deploy_create{value: msgValue}(cachedInitCode);
        assertEq(newContract, computedAddress);
        assertNotEq(newContract, zeroAddress);
        assertNotEq(newContract.code.length, 0);
        assertEq(newContract.balance, msgValue);
        assertEq(createAddr.balance, 0);
        assertEq(ERC20Mock(computedAddress).name(), _NAME);
        assertEq(ERC20Mock(computedAddress).symbol(), _SYMBOL);
        assertEq(ERC20Mock(computedAddress).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testDeployCreateRevert() public {
        /**
         * @dev Deploy the invalid runtime bytecode `0xef0100` (see https://eips.ethereum.org/EIPS/eip-3541).
         */
        bytes memory invalidInitCode = hex"60_ef_60_00_53_60_01_60_01_53_60_03_60_00_f3";
        address computedAddress = create.compute_create_address(createAddr, 1);
        vm.expectRevert();
        create.deploy_create(invalidInitCode);
        assertEq(computedAddress.code.length, 0);
        assertEq(computedAddress.balance, 0);
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
        uint64 nonce = 0x7f;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint8() public {
        uint64 nonce = type(uint8).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint16() public {
        uint64 nonce = type(uint16).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint24() public {
        uint64 nonce = type(uint24).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint32() public {
        uint64 nonce = type(uint32).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint40() public {
        uint64 nonce = type(uint40).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint48() public {
        uint64 nonce = type(uint48).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint56() public {
        uint64 nonce = type(uint56).max;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressNonceUint64() public {
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(self, nonce);
        address createAddressComputed = create.compute_create_address(self, nonce);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonce0x7f() public {
        uint64 nonce = 0x7f;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint8() public {
        uint64 nonce = type(uint8).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint16() public {
        uint64 nonce = type(uint16).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint24() public {
        uint64 nonce = type(uint24).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint32() public {
        uint64 nonce = type(uint32).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint40() public {
        uint64 nonce = type(uint40).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint48() public {
        uint64 nonce = type(uint48).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint56() public {
        uint64 nonce = type(uint56).max;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testComputeCreateAddressSelfNonceUint64() public {
        uint64 nonce = uint64(type(uint64).max) - 1;
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzDeployCreateValueSuccess(uint64 nonce, uint256 msgValue) public {
        vm.assume(nonce != 0 && nonce < type(uint64).max);
        vm.setNonceUnsafe(createAddr, nonce);
        msgValue = bound(msgValue, 0, type(uint64).max);
        address computedAddress = create.compute_create_address(createAddr, nonce);
        vm.expectEmit(true, true, false, true, computedAddress);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create.deploy_create{value: msgValue}(cachedInitCode);
        assertEq(newContract, computedAddress);
        assertNotEq(newContract, zeroAddress);
        assertNotEq(newContract.code.length, 0);
        assertEq(newContract.balance, msgValue);
        assertEq(createAddr.balance, 0);
        assertEq(ERC20Mock(computedAddress).name(), _NAME);
        assertEq(ERC20Mock(computedAddress).symbol(), _SYMBOL);
        assertEq(ERC20Mock(computedAddress).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testFuzzDeployCreateRevert(uint64 nonce, uint256 msgValue) public {
        vm.assume(nonce != 0 && nonce < type(uint64).max);
        vm.setNonceUnsafe(createAddr, nonce);
        msgValue = bound(msgValue, 0, type(uint64).max);
        /**
         * @dev Deploy the invalid runtime bytecode `0xef0100` (see https://eips.ethereum.org/EIPS/eip-3541).
         */
        bytes memory invalidInitCode = hex"60_ef_60_00_53_60_01_60_01_53_60_03_60_00_f3";
        address computedAddress = create.compute_create_address(createAddr, 1);
        vm.expectRevert();
        create.deploy_create{value: msgValue}(invalidInitCode);
        assertEq(computedAddress.code.length, 0);
        assertEq(computedAddress.balance, 0);
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
        nonce = uint64(bound(uint256(nonce), vm.getNonce(deployer) + 1, 0x7f));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint8(uint64 nonce, address deployer) public {
        nonce = uint64(bound(nonce, 0x7f + 1, uint256(type(uint8).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint16(uint64 nonce, address deployer) public {
        nonce = uint64(bound(nonce, uint64(type(uint8).max) + 1, uint64(type(uint16).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint24(uint64 nonce, address deployer) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint16).max) + 1, uint256(type(uint24).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint32(uint64 nonce, address deployer) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint24).max) + 1, uint256(type(uint32).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint40(uint64 nonce, address deployer) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint32).max) + 1, uint256(type(uint40).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint48(uint64 nonce, address deployer) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint40).max) + 1, uint256(type(uint48).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint56(uint64 nonce, address deployer) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint48).max) + 1, uint256(type(uint56).max)));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressNonceUint64(uint64 nonce, address deployer) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint56).max) + 1, uint256(type(uint64).max) - 1));
        vm.setNonce(deployer, nonce);
        address createAddressComputed = create.compute_create_address(deployer, nonce);

        vm.prank(deployer);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonce0x7f(uint64 nonce) public {
        nonce = uint64(bound(nonce, vm.getNonce(createAddr) + 1, 0x7f));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint8(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), 0x7f + 1, uint256(type(uint8).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint16(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint8).max) + 1, uint256(type(uint16).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint24(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint16).max) + 1, uint256(type(uint24).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint32(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint24).max) + 1, uint256(type(uint32).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint40(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint32).max) + 1, uint256(type(uint40).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint48(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint40).max) + 1, uint256(type(uint48).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint56(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint48).max) + 1, uint256(type(uint56).max)));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }

    function testFuzzComputeCreateAddressSelfNonceUint64(uint64 nonce) public {
        nonce = uint64(bound(uint256(nonce), uint256(type(uint56).max) + 1, uint256(type(uint64).max) - 1));
        vm.setNonce(createAddr, nonce);
        address createAddressComputed = create.compute_create_address_self(nonce);

        vm.startPrank(createAddr);
        ERC20Mock createAddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(createAddressComputed, vm.computeCreateAddress(createAddr, nonce));
        assertEq(createAddressComputed, address(createAddressComputedOnChain));
    }
}
