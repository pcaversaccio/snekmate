// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {ICreate2} from "./interfaces/ICreate2.sol";

contract Create2Test is Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "MTKN";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;
    bytes32 private constant _SALT = keccak256("Long Live Vyper!");

    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICreate2 private create2;

    address private zeroAddress = address(0);
    address private create2Addr;
    address private initialAccount;
    bytes private cachedInitCode;
    bytes32 private bytecodeHash;

    function setUp() public {
        initialAccount = makeAddr("initialAccount");
        bytes memory args = abi.encode(_NAME, _SYMBOL, initialAccount, _INITIAL_SUPPLY);
        cachedInitCode = abi.encodePacked(type(ERC20Mock).creationCode, args);
        bytecodeHash = keccak256(cachedInitCode);
        create2 = ICreate2(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "create2_mock"));
        create2Addr = address(create2);
    }

    function testDeployCreate2Success() public {
        address create2AddressComputed = create2.compute_create2_address(_SALT, bytecodeHash, create2Addr);
        vm.expectEmit(true, true, false, true, create2AddressComputed);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create2.deploy_create2(_SALT, cachedInitCode);
        assertEq(newContract, vm.computeCreate2Address(_SALT, bytecodeHash, create2Addr));
        assertEq(newContract, create2AddressComputed);
        assertTrue(newContract != zeroAddress);
        assertTrue(newContract.code.length != 0);
        assertEq(newContract.balance, 0);
        assertEq(create2Addr.balance, 0);
        assertEq(ERC20Mock(create2AddressComputed).name(), _NAME);
        assertEq(ERC20Mock(create2AddressComputed).symbol(), _SYMBOL);
        assertEq(ERC20Mock(create2AddressComputed).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testDeployCreate2ValueSuccess() public {
        uint256 msgValue = 1_337;
        address create2AddressComputed = create2.compute_create2_address(_SALT, bytecodeHash, create2Addr);
        vm.expectEmit(true, true, false, true, create2AddressComputed);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create2.deploy_create2{value: msgValue}(_SALT, cachedInitCode);
        assertEq(newContract, vm.computeCreate2Address(_SALT, bytecodeHash, create2Addr));
        assertEq(newContract, create2AddressComputed);
        assertTrue(newContract != zeroAddress);
        assertTrue(newContract.code.length != 0);
        assertEq(newContract.balance, msgValue);
        assertEq(create2Addr.balance, 0);
        assertEq(ERC20Mock(create2AddressComputed).name(), _NAME);
        assertEq(ERC20Mock(create2AddressComputed).symbol(), _SYMBOL);
        assertEq(ERC20Mock(create2AddressComputed).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testDeployCreate2Revert() public {
        /**
         * @dev Deploy the invalid runtime bytecode `0xef0100` (see https://eips.ethereum.org/EIPS/eip-3541).
         */
        bytes memory invalidInitCode = hex"60_ef_60_00_53_60_01_60_01_53_60_03_60_00_f3";
        address create2AddressComputed = create2.compute_create2_address(_SALT, bytecodeHash, create2Addr);
        vm.expectRevert();
        create2.deploy_create2(_SALT, invalidInitCode);
        assertEq(create2AddressComputed.code.length, 0);
        assertEq(create2AddressComputed.balance, 0);
    }

    function testComputeCreate2Address() public {
        address create2AddressComputed = create2.compute_create2_address(_SALT, bytecodeHash, address(this));
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: _SALT}(
            _NAME,
            _SYMBOL,
            initialAccount,
            _INITIAL_SUPPLY
        );
        assertEq(create2AddressComputed, vm.computeCreate2Address(_SALT, bytecodeHash, address(this)));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }

    function testComputeCreate2AddressSelf() public {
        address create2AddressComputed = create2.compute_create2_address_self(_SALT, bytecodeHash);
        vm.startPrank(create2Addr);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: _SALT}(
            _NAME,
            _SYMBOL,
            initialAccount,
            _INITIAL_SUPPLY
        );
        vm.stopPrank();
        assertEq(create2AddressComputed, vm.computeCreate2Address(_SALT, bytecodeHash, create2Addr));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }

    function testFuzzDeployCreate2ValueSuccess(uint256 msgValue, bytes32 salt) public {
        msgValue = bound(msgValue, 0, type(uint64).max);
        address create2AddressComputed = create2.compute_create2_address(salt, bytecodeHash, create2Addr);
        vm.expectEmit(true, true, false, true, create2AddressComputed);
        emit IERC20.Transfer(zeroAddress, initialAccount, _INITIAL_SUPPLY);
        address newContract = create2.deploy_create2{value: msgValue}(salt, cachedInitCode);
        assertEq(newContract, vm.computeCreate2Address(salt, bytecodeHash, create2Addr));
        assertEq(newContract, create2AddressComputed);
        assertTrue(newContract != zeroAddress);
        assertTrue(newContract.code.length != 0);
        assertEq(newContract.balance, msgValue);
        assertEq(create2Addr.balance, 0);
        assertEq(ERC20Mock(create2AddressComputed).name(), _NAME);
        assertEq(ERC20Mock(create2AddressComputed).symbol(), _SYMBOL);
        assertEq(ERC20Mock(create2AddressComputed).balanceOf(initialAccount), _INITIAL_SUPPLY);
    }

    function testFuzzDeployCreate2Revert(uint256 msgValue, bytes32 salt) public {
        msgValue = bound(msgValue, 0, type(uint64).max);
        /**
         * @dev Deploy the invalid runtime bytecode `0xef0100` (see https://eips.ethereum.org/EIPS/eip-3541).
         */
        bytes memory invalidInitCode = hex"60_ef_60_00_53_60_01_60_01_53_60_03_60_00_f3";
        address create2AddressComputed = create2.compute_create2_address(salt, bytecodeHash, create2Addr);
        vm.expectRevert();
        create2.deploy_create2{value: msgValue}(salt, invalidInitCode);
        assertEq(create2AddressComputed.code.length, 0);
        assertEq(create2AddressComputed.balance, 0);
    }

    function testFuzzComputeCreate2Address(bytes32 salt, address deployer) public {
        address create2AddressComputed = create2.compute_create2_address(salt, bytecodeHash, deployer);
        vm.startPrank(deployer);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(
            _NAME,
            _SYMBOL,
            initialAccount,
            _INITIAL_SUPPLY
        );
        vm.stopPrank();
        assertEq(create2AddressComputed, vm.computeCreate2Address(salt, bytecodeHash, deployer));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }

    function testFuzzComputeCreate2AddressSelf(bytes32 salt) public {
        address create2AddressComputed = create2.compute_create2_address_self(salt, bytecodeHash);
        vm.startPrank(create2Addr);
        ERC20Mock create2AddressComputedOnChain = new ERC20Mock{salt: salt}(
            _NAME,
            _SYMBOL,
            initialAccount,
            _INITIAL_SUPPLY
        );
        vm.stopPrank();
        assertEq(create2AddressComputed, vm.computeCreate2Address(salt, bytecodeHash, create2Addr));
        assertEq(create2AddressComputed, address(create2AddressComputedOnChain));
    }
}
