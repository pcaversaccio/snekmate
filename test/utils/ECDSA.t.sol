// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IECDSA} from "../../test/utils/IECDSA.sol";

contract ECDSATest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    // solhint-disable-next-line var-name-mixedcase
    IECDSA private ECDSA;

    function setUp() public {
        ECDSA = IECDSA(vyperDeployer.deployContract("src/utils/", "ECDSA"));
    }

    // solhint-disable-next-line func-name-mixedcase
    function test_recover_sig() public {
        address alice = vm.addr(1);
        bytes32 hash = keccak256("WAGMI");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(alice, ECDSA._recover_sig(hash, signature));
    }
}
