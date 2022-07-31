// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

contract SimpleStoreTest is Test {
    ///@notice create a new instance of VyperDeployer
    VyperDeployer vyperDeployer = new VyperDeployer();

    ISimpleStore simpleStore;

    function setUp() public {
        ///@notice deploy a new instance of ISimplestore by passing in the address of the deployed Vyper contract
        simpleStore = ISimpleStore(
            vyperDeployer.deployContract("SimpleStore", abi.encode(1234))
        );
    }

    function testGet() public {
        uint256 val = simpleStore.get();

        require(val == 1234);
    }

    function testStore(uint256 _val) public {
        simpleStore.store(_val);
        uint256 val = simpleStore.get();

        require(_val == val);
    }
}
