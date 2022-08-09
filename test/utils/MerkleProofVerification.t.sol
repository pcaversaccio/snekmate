// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.15;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IMerkleProofVerification} from "../../test/utils/interfaces/IMerkleProofVerification.sol";

contract MerkleProofVerificationTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IMerkleProofVerification private merkleProofVerification;

    function setUp() public {
        merkleProofVerification = IMerkleProofVerification(
            vyperDeployer.deployContract(
                "src/utils/",
                "MerkleProofVerification"
            )
        );
    }
}
