// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.18;

import {ERC4626Test} from "erc4626-tests/ERC4626.test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ERC20Mock} from "../utils/mocks/ERC20Mock.sol";

import {IERC4626Extended} from "./interfaces/IERC4626Extended.sol";

contract ERC4626VaultTest is ERC4626Test {
    string private constant _NAME = "TokenisedVaultMock";
    string private constant _NAME_UNDERLYING = "UnderlyingTokenMock";
    string private constant _SYMBOL = "TVM";
    string private constant _SYMBOL_UNDERLYING = "UTM";
    string private constant _NAME_EIP712 = "TokenisedVaultMock";
    string private constant _VERSION_EIP712 = "1";
    uint8 private constant _DECIMALS_OFFSET = 0;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 private constant _PERMIT_TYPE_HASH =
        keccak256(
            bytes(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
            )
        );

    VyperDeployer private vyperDeployer = new VyperDeployer();
    ERC20Mock private underlying =
        new ERC20Mock(
            _NAME_UNDERLYING,
            _SYMBOL_UNDERLYING,
            makeAddr("initialAccount"),
            100
        );

    /* solhint-disable var-name-mixedcase */
    IERC4626Extended private ERC4626Extended;
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    /* solhint-enable var-name-mixedcase */

    address private deployer = address(vyperDeployer);
    address private self = address(this);
    address private zeroAddress = address(0);
    // solhint-disable-next-line var-name-mixedcase
    address private ERC4626ExtendedAddr;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function setUp() public override {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            underlying,
            _DECIMALS_OFFSET,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC4626Extended = IERC4626Extended(
            vyperDeployer.deployContract("src/extensions/", "ERC4626", args)
        );
        ERC4626ExtendedAddr = address(ERC4626Extended);
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC4626ExtendedAddr
            )
        );

        _underlying_ = address(underlying);
        _vault_ = ERC4626ExtendedAddr;
        _delta_ = 0;
        _vaultMayBeEmpty = false;
        _unlimitedAmount = true;
    }

    function testInitialSetup() public {
        assertEq(ERC4626Extended.name(), _NAME);
        assertEq(ERC4626Extended.decimals(), 18);
        assertEq(ERC4626Extended.symbol(), _SYMBOL);
    }
}
