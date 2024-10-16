// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.28;

import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC721Internal} from "properties/ERC721/util/IERC721Internal.sol";
import {MockReceiver} from "properties/ERC721/external/util/MockReceiver.sol";

import {CryticERC721ExternalBasicProperties} from "properties/ERC721/external/properties/ERC721ExternalBasicProperties.sol";
import {CryticERC721ExternalBurnableProperties} from "properties/ERC721/external/properties/ERC721ExternalBurnableProperties.sol";
import {CryticERC721ExternalMintableProperties} from "properties/ERC721/external/properties/ERC721ExternalMintableProperties.sol";

contract CryticERC721ExternalHarness is
    CryticERC721ExternalBasicProperties,
    CryticERC721ExternalBurnableProperties,
    CryticERC721ExternalMintableProperties
{
    string private constant _NAME = "MyNFT";
    string private constant _SYMBOL = "WAGMI";
    string private constant _BASE_URI = "https://www.wagmi.xyz/";
    string private constant _NAME_EIP712 = "MyNFT";
    string private constant _VERSION_EIP712 = "1";

    VyperDeployer private vyperDeployer = new VyperDeployer();

    constructor() {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _BASE_URI,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        /**
         * @dev `hevm` does not currently work with the EVM version `cancun`:
         * https://github.com/ethereum/hevm/issues/469. For Echidna-based tests,
         * we therefore use the EVM version `shanghai`.
         */
        token = IERC721Internal(
            vyperDeployer.deployContract(
                "src/snekmate/tokens/mocks/",
                "erc721_mock",
                args,
                "shanghai",
                "gas"
            )
        );
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }

    function test_ERC721_external_mintIncreasesSupply(
        uint256 amount
    ) public override {
        amount = clampBetween(amount, 0, 64);
        super.test_ERC721_external_mintIncreasesSupply(amount);
    }

    function test_ERC721_external_mintCreatesFreshToken(
        uint256 amount
    ) public override {
        amount = clampBetween(amount, 0, 64);
        super.test_ERC721_external_mintCreatesFreshToken(amount);
    }
}
