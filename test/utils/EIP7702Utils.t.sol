// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IEIP7702Utils} from "./interfaces/IEIP7702Utils.sol";

contract EIP7702UtilsTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IEIP7702Utils private EIP7702utils;

    address private self = address(this);
    address private zeroAddress = address(0);

    function setUp() public {
        EIP7702utils = IEIP7702Utils(vyperDeployer.deployContract("src/snekmate/utils/mocks/", "eip7702_utils_mock"));
    }

    function testEOAWithoutDelegation() public {
        address account = makeAddr("account");
        assertEq(EIP7702utils.fetch_delegate(account), zeroAddress);
    }

    function testEOAWithDelegation() public {
        (address account, uint256 key) = makeAddrAndKey("account");
        vm.signAndAttachDelegation(self, key);
        assertEq(EIP7702utils.fetch_delegate(account), self);
    }

    function testEOAWithRevokedDelegation() public {
        (address account, uint256 key) = makeAddrAndKey("account");
        vm.signAndAttachDelegation(self, key);
        vm.signAndAttachDelegation(zeroAddress, key);
        assertEq(EIP7702utils.fetch_delegate(account), zeroAddress);
    }

    function testSomeShortSmartContract() public {
        address account = makeAddr("account");
        vm.etch(account, hex"604260005260206000F3");
        assertEq(EIP7702utils.fetch_delegate(self), zeroAddress);
    }

    function testSomeOtherSmartContract() public view {
        assertEq(EIP7702utils.fetch_delegate(self), zeroAddress);
    }

    function testFuzzEOAWithoutDelegation(address account) public view {
        assertEq(EIP7702utils.fetch_delegate(account), zeroAddress);
    }

    function testFuzzEOAWithDelegation(string calldata signer, address delegation) public {
        (address account, uint256 key) = makeAddrAndKey(signer);
        vm.signAndAttachDelegation(delegation, key);
        assertEq(EIP7702utils.fetch_delegate(account), delegation);
    }

    function testFuzzEOAWithRevokedDelegation(string calldata signer, address delegation) public {
        (address account, uint256 key) = makeAddrAndKey(signer);
        vm.signAndAttachDelegation(delegation, key);
        vm.signAndAttachDelegation(zeroAddress, key);
        assertEq(EIP7702utils.fetch_delegate(account), zeroAddress);
    }
}
