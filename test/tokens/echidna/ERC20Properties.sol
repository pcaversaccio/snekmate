// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.33;

import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ITokenMock} from "properties/ERC20/external/util/ITokenMock.sol";

import {CryticERC20ExternalBasicProperties} from "properties/ERC20/external/properties/ERC20ExternalBasicProperties.sol";
import {CryticERC20ExternalBurnableProperties} from "properties/ERC20/external/properties/ERC20ExternalBurnableProperties.sol";
import {CryticERC20ExternalMintableProperties} from "properties/ERC20/external/properties/ERC20ExternalMintableProperties.sol";

contract CryticERC20ExternalHarness is
    CryticERC20ExternalBasicProperties,
    CryticERC20ExternalBurnableProperties,
    CryticERC20ExternalMintableProperties
{
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "WAGMI";
    uint8 private constant _DECIMALS = 18;
    string private constant _NAME_EIP712 = "MyToken";
    string private constant _VERSION_EIP712 = "1";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    constructor() {
        bytes memory args = abi.encode(_NAME, _SYMBOL, _DECIMALS, _INITIAL_SUPPLY, _NAME_EIP712, _VERSION_EIP712);
        token = ITokenMock(vyperDeployer.deployContract("src/snekmate/tokens/mocks/", "erc20_mock", args));
    }
}
