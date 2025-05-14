// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreate3} from "./interfaces/ICreate3.sol";

contract Create3Test is Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "MTKN";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;
    bytes32 private constant _SALT = keccak256("Long Live Vyper!");
    bytes32 private constant proxyBytecodeHash =
        keccak256(abi.encodePacked(hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3"));
    bytes32 private constant proxyRuntimeBytecodeHash = keccak256(abi.encodePacked(hex"36_3d_3d_37_36_3d_34_f0"));

    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICreate3 private create3;

    address private zeroAddress = address(0);
    address private create3Addr;
    address private initialAccount;
    bytes private cachedInitCode;
    bytes32 private bytecodeHash;

    function setUp() public {
        initialAccount = makeAddr("initialAccount");
        bytes memory args = abi.encode(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        cachedInitCode = abi.encodePacked(type(ERC20Mock).creationCode, args);
        bytecodeHash = keccak256(cachedInitCode);
        create3 = ICreate3(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "create3_mock"));
        create3Addr = address(create3);
    }

    function testDeployCreate3Success() public {
        address create3AddressComputed = create3.compute_create3_address(_SALT, create3Addr);
        address proxy = vm.computeCreate2Address(_SALT, proxyBytecodeHash, create3Addr);
        vm.expectEmit(true, true, false, true, create3AddressComputed);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create3.deploy_create3(_SALT, cachedInitCode);
        assertEq(keccak256(abi.encodePacked(proxy.code)), proxyRuntimeBytecodeHash);
        assertEq(newContract, create3AddressComputed);
        assertTrue(newContract != zeroAddress);
        assertTrue(newContract.code.length != 0);
        assertEq(newContract.balance, 0);
        assertEq(create3Addr.balance, 0);
        assertEq(ERC20Mock(create3AddressComputed).name(), _NAME);
        assertEq(ERC20Mock(create3AddressComputed).symbol(), _SYMBOL);
        assertEq(ERC20Mock(create3AddressComputed).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testDeployCreate3ValueSuccess() public {
        uint256 msgValue = 1_337;
        address create3AddressComputed = create3.compute_create3_address(_SALT, create3Addr);
        address proxy = vm.computeCreate2Address(_SALT, proxyBytecodeHash, create3Addr);
        vm.expectEmit(true, true, false, true, create3AddressComputed);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create3.deploy_create3{value: msgValue}(_SALT, cachedInitCode);
        assertEq(keccak256(abi.encodePacked(proxy.code)), proxyRuntimeBytecodeHash);
        assertEq(newContract, create3AddressComputed);
        assertTrue(newContract != zeroAddress);
        assertTrue(newContract.code.length != 0);
        assertEq(newContract.balance, msgValue);
        assertEq(create3Addr.balance, 0);
        assertEq(ERC20Mock(create3AddressComputed).name(), _NAME);
        assertEq(ERC20Mock(create3AddressComputed).symbol(), _SYMBOL);
        assertEq(ERC20Mock(create3AddressComputed).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testDeployCreate3ProxyCreationFails() public {
        address create3AddressComputed = create3.compute_create3_address(_SALT, create3Addr);
        address proxy = vm.computeCreate2Address(_SALT, proxyBytecodeHash, create3Addr);
        vm.etch(proxy, hex"01");
        vm.expectRevert();
        create3.deploy_create3(_SALT, cachedInitCode);
        assertEq(create3AddressComputed.code.length, 0);
        assertEq(create3AddressComputed.balance, 0);
    }

    function testDeployCreate3Revert() public {
        /**
         * @dev Deploy the invalid runtime bytecode `0xef0100` (see https://eips.ethereum.org/EIPS/eip-3541).
         */
        bytes memory invalidInitCode = hex"60_ef_60_00_53_60_01_60_01_53_60_03_60_00_f3";
        address create3AddressComputed = create3.compute_create3_address(_SALT, create3Addr);
        vm.expectRevert("create3: contract creation failed");
        create3.deploy_create3(_SALT, invalidInitCode);
        assertEq(create3AddressComputed.code.length, 0);
        assertEq(create3AddressComputed.balance, 0);
    }

    function testDeployCreate3ZeroLengthBytecode() public {
        address create3AddressComputed = create3.compute_create3_address(_SALT, create3Addr);
        vm.expectRevert("create3: contract creation failed");
        create3.deploy_create3(_SALT, new bytes(0));
        assertEq(create3AddressComputed.code.length, 0);
        assertEq(create3AddressComputed.balance, 0);
    }

    function testComputeCreate3Address() public {
        address create3AddressComputed = create3.compute_create3_address(_SALT, create3Addr);
        address proxy = vm.computeCreate2Address(_SALT, proxyBytecodeHash, create3Addr);
        vm.setNonce(proxy, 1);
        vm.startPrank(proxy);
        ERC20Mock create3AddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(create3AddressComputed, vm.computeCreateAddress(proxy, 1));
        assertEq(create3AddressComputed, address(create3AddressComputedOnChain));
    }

    function testComputeCreate3AddressSelf() public {
        address create3AddressComputed = create3.compute_create3_address_self(_SALT);
        address proxy = vm.computeCreate2Address(_SALT, proxyBytecodeHash, create3Addr);
        vm.setNonce(proxy, 1);
        vm.startPrank(proxy);
        ERC20Mock create3AddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(create3AddressComputed, vm.computeCreateAddress(proxy, 1));
        assertEq(create3AddressComputed, address(create3AddressComputedOnChain));
    }

    function testFuzzDeployCreate3ValueSuccess(uint256 msgValue, bytes32 salt) public {
        msgValue = bound(msgValue, 0, type(uint64).max);
        address create3AddressComputed = create3.compute_create3_address(salt, create3Addr);
        address proxy = vm.computeCreate2Address(salt, proxyBytecodeHash, create3Addr);
        vm.expectEmit(true, true, false, true, create3AddressComputed);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create3.deploy_create3{value: msgValue}(salt, cachedInitCode);
        assertEq(keccak256(abi.encodePacked(proxy.code)), proxyRuntimeBytecodeHash);
        assertEq(newContract, create3AddressComputed);
        assertTrue(newContract != zeroAddress);
        assertTrue(newContract.code.length != 0);
        assertEq(newContract.balance, msgValue);
        assertEq(create3Addr.balance, 0);
        assertEq(ERC20Mock(create3AddressComputed).name(), _NAME);
        assertEq(ERC20Mock(create3AddressComputed).symbol(), _SYMBOL);
        assertEq(ERC20Mock(create3AddressComputed).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testFuzzDeployCreate3ProxyCreationFails(uint256 msgValue, bytes32 salt) public {
        msgValue = bound(msgValue, 0, type(uint64).max);
        address create3AddressComputed = create3.compute_create3_address(salt, create3Addr);
        address proxy = vm.computeCreate2Address(salt, proxyBytecodeHash, create3Addr);
        vm.etch(proxy, hex"01");
        vm.expectRevert();
        create3.deploy_create3{value: msgValue}(salt, cachedInitCode);
        assertEq(create3AddressComputed.code.length, 0);
        assertEq(create3AddressComputed.balance, 0);
    }

    function testFuzzDeployCreate3Revert(uint256 msgValue, bytes32 salt) public {
        msgValue = bound(msgValue, 0, type(uint64).max);
        /**
         * @dev Deploy the invalid runtime bytecode `0xef0100` (see https://eips.ethereum.org/EIPS/eip-3541).
         */
        bytes memory invalidInitCode = hex"60_ef_60_00_53_60_01_60_01_53_60_03_60_00_f3";
        address create3AddressComputed = create3.compute_create3_address(salt, create3Addr);
        vm.expectRevert("create3: contract creation failed");
        create3.deploy_create3{value: msgValue}(salt, invalidInitCode);
        assertEq(create3AddressComputed.code.length, 0);
        assertEq(create3AddressComputed.balance, 0);
    }

    function testFuzzDeployCreate3ZeroLengthBytecode(uint256 msgValue, bytes32 salt) public {
        msgValue = bound(msgValue, 0, type(uint64).max);
        address create3AddressComputed = create3.compute_create3_address(salt, create3Addr);
        vm.expectRevert("create3: contract creation failed");
        create3.deploy_create3{value: msgValue}(salt, new bytes(0));
        assertEq(create3AddressComputed.code.length, 0);
        assertEq(create3AddressComputed.balance, 0);
    }

    function testFuzzComputeCreate3Address(bytes32 salt) public {
        address create3AddressComputed = create3.compute_create3_address(salt, create3Addr);
        address proxy = vm.computeCreate2Address(salt, proxyBytecodeHash, create3Addr);
        vm.setNonce(proxy, 1);
        vm.startPrank(proxy);
        ERC20Mock create3AddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(create3AddressComputed, vm.computeCreateAddress(proxy, 1));
        assertEq(create3AddressComputed, address(create3AddressComputedOnChain));
    }

    function testFuzzComputeCreate3AddressSelf(bytes32 salt) public {
        address create3AddressComputed = create3.compute_create3_address_self(salt);
        address proxy = vm.computeCreate2Address(salt, proxyBytecodeHash, create3Addr);
        vm.setNonce(proxy, 1);
        vm.startPrank(proxy);
        ERC20Mock create3AddressComputedOnChain = new ERC20Mock(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        vm.stopPrank();
        assertEq(create3AddressComputed, vm.computeCreateAddress(proxy, 1));
        assertEq(create3AddressComputed, address(create3AddressComputedOnChain));
    }
}
