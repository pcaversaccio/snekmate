// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";
import {EIP712External} from "../../lib/openzeppelin-contracts/contracts/mocks/EIP712External.sol";
// import {console} from "../../lib/forge-std/src/console.sol";

import {IEIP712} from "../../test/utils/interfaces/IEIP712.sol";

contract CreateAddressTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();
    // solhint-disable-next-line var-name-mixedcase
    IEIP712 private EIP712;

    string private constant _NAME = "WAGMI";
    string private constant _VERSION = "1";

    EIP712External private eip712External = new EIP712External(_NAME, _VERSION);

    function setUp() public {
        bytes memory args = abi.encode(_NAME, _VERSION);
        EIP712 = IEIP712(
            vyperDeployer.deployContract("src/utils/", "EIP712", args)
        );
    }

    // function testDomainSeparatorV4() public {
    // assertEq(EIP712.domain_separator_v4(), eip712External.domainSeparator());
    // console.logBytes32(EIP712.domain_separator_v4());
    // }

    // function testHashTypedDataV4() public {}
}
