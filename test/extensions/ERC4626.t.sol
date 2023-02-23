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
    IERC4626Extended private ERC4626ExtendedDecimalsOffset0;
    IERC4626Extended private ERC4626ExtendedDecimalsOffset6;
    IERC4626Extended private ERC4626ExtendedDecimalsOffset12;
    IERC4626Extended private ERC4626ExtendedDecimalsOffset18;
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    /* solhint-enable var-name-mixedcase */

    address private deployer = address(vyperDeployer);
    address private underlyingAddr = address(underlying);
    address private zeroAddress = address(0);
    /* solhint-disable var-name-mixedcase */
    address private ERC4626ExtendedDecimalsOffset0Addr;
    address private ERC4626ExtendedDecimalsOffset6Addr;
    address private ERC4626ExtendedDecimalsOffset12Addr;
    address private ERC4626ExtendedDecimalsOffset18Addr;
    /* solhint-enable var-name-mixedcase */

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
        bytes memory argsDecimalsOffset0 = abi.encode(
            _NAME,
            _SYMBOL,
            underlying,
            _DECIMALS_OFFSET,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC4626ExtendedDecimalsOffset0 = IERC4626Extended(
            vyperDeployer.deployContract(
                "src/extensions/",
                "ERC4626",
                argsDecimalsOffset0
            )
        );
        ERC4626ExtendedDecimalsOffset0Addr = address(
            ERC4626ExtendedDecimalsOffset0
        );
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC4626ExtendedDecimalsOffset0Addr
            )
        );

        bytes memory argsDecimalsOffset6 = abi.encode(
            _NAME,
            _SYMBOL,
            underlying,
            _DECIMALS_OFFSET + 6,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC4626ExtendedDecimalsOffset6 = IERC4626Extended(
            vyperDeployer.deployContract(
                "src/extensions/",
                "ERC4626",
                argsDecimalsOffset6
            )
        );
        ERC4626ExtendedDecimalsOffset6Addr = address(
            ERC4626ExtendedDecimalsOffset6
        );

        bytes memory argsDecimalsOffset12 = abi.encode(
            _NAME,
            _SYMBOL,
            underlying,
            _DECIMALS_OFFSET + 12,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC4626ExtendedDecimalsOffset12 = IERC4626Extended(
            vyperDeployer.deployContract(
                "src/extensions/",
                "ERC4626",
                argsDecimalsOffset12
            )
        );
        ERC4626ExtendedDecimalsOffset12Addr = address(
            ERC4626ExtendedDecimalsOffset12
        );

        bytes memory argsDecimalsOffset18 = abi.encode(
            _NAME,
            _SYMBOL,
            underlying,
            _DECIMALS_OFFSET + 18,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC4626ExtendedDecimalsOffset18 = IERC4626Extended(
            vyperDeployer.deployContract(
                "src/extensions/",
                "ERC4626",
                argsDecimalsOffset18
            )
        );
        ERC4626ExtendedDecimalsOffset18Addr = address(
            ERC4626ExtendedDecimalsOffset18
        );

        /**
         * @dev ERC-4626 property tests (https://github.com/a16z/erc4626-tests) setup.
         */
        _underlying_ = underlyingAddr;
        _vault_ = ERC4626ExtendedDecimalsOffset0Addr;
        _delta_ = 0;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = true;
    }

    function testInitialSetup() public {
        assertEq(ERC4626ExtendedDecimalsOffset0.name(), _NAME);
        assertEq(ERC4626ExtendedDecimalsOffset0.symbol(), _SYMBOL);
        assertEq(ERC4626ExtendedDecimalsOffset0.decimals(), 18);
        assertEq(ERC4626ExtendedDecimalsOffset0.asset(), underlyingAddr);

        assertEq(ERC4626ExtendedDecimalsOffset6.name(), _NAME);
        assertEq(ERC4626ExtendedDecimalsOffset6.symbol(), _SYMBOL);
        assertEq(ERC4626ExtendedDecimalsOffset6.decimals(), 18 + 6);
        assertEq(ERC4626ExtendedDecimalsOffset6.asset(), underlyingAddr);

        assertEq(ERC4626ExtendedDecimalsOffset12.name(), _NAME);
        assertEq(ERC4626ExtendedDecimalsOffset12.symbol(), _SYMBOL);
        assertEq(ERC4626ExtendedDecimalsOffset12.decimals(), 18 + 12);
        assertEq(ERC4626ExtendedDecimalsOffset12.asset(), underlyingAddr);

        assertEq(ERC4626ExtendedDecimalsOffset18.name(), _NAME);
        assertEq(ERC4626ExtendedDecimalsOffset18.symbol(), _SYMBOL);
        assertEq(ERC4626ExtendedDecimalsOffset18.decimals(), 18 + 18);
        assertEq(ERC4626ExtendedDecimalsOffset18.asset(), underlyingAddr);

        /**
         * @dev Check the case where the asset has not yet been created.
         */
        bytes memory argsDecimalsOffsetEOA = abi.encode(
            _NAME,
            _SYMBOL,
            makeAddr("someAccount"),
            _DECIMALS_OFFSET + 3,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        // solhint-disable-next-line var-name-mixedcase
        IERC4626Extended ERC4626ExtendedDecimalsOffsetEOA = IERC4626Extended(
            vyperDeployer.deployContract(
                "src/extensions/",
                "ERC4626",
                argsDecimalsOffsetEOA
            )
        );
        assertEq(ERC4626ExtendedDecimalsOffsetEOA.name(), _NAME);
        assertEq(ERC4626ExtendedDecimalsOffsetEOA.symbol(), _SYMBOL);
        assertEq(ERC4626ExtendedDecimalsOffsetEOA.decimals(), 18 + 3);
        assertEq(
            ERC4626ExtendedDecimalsOffsetEOA.asset(),
            makeAddr("someAccount")
        );

        /**
         * @dev Check the case where success is `False`.
         */
        bytes memory argsDecimalsOffsetNoDecimals = abi.encode(
            _NAME,
            _SYMBOL,
            deployer,
            _DECIMALS_OFFSET + 6,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        // solhint-disable-next-line var-name-mixedcase
        IERC4626Extended ERC4626ExtendedDecimalsOffsetNoDecimals = IERC4626Extended(
                vyperDeployer.deployContract(
                    "src/extensions/",
                    "ERC4626",
                    argsDecimalsOffsetNoDecimals
                )
            );
        assertEq(ERC4626ExtendedDecimalsOffsetNoDecimals.name(), _NAME);
        assertEq(ERC4626ExtendedDecimalsOffsetNoDecimals.symbol(), _SYMBOL);
        assertEq(ERC4626ExtendedDecimalsOffsetNoDecimals.decimals(), 18 + 6);
        assertEq(ERC4626ExtendedDecimalsOffsetNoDecimals.asset(), deployer);

        bytes memory argsDecimalsOffsetOverflow = abi.encode(
            _NAME,
            _SYMBOL,
            underlying,
            type(uint8).max,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        vm.expectRevert();
        IERC4626Extended(
            vyperDeployer.deployContract(
                "src/extensions/",
                "ERC4626",
                argsDecimalsOffsetOverflow
            )
        );
    }

    function testEmptyVaultDeposit() public {
        address holder = makeAddr("holder");
        address receiver = makeAddr("receiver");
        uint256 assets = 1;
        uint256 shares = 1;
        vm.startPrank(holder);
        underlying.mint(holder, type(uint16).max);
        underlying.approve(
            ERC4626ExtendedDecimalsOffset0Addr,
            type(uint256).max
        );
        underlying.approve(
            ERC4626ExtendedDecimalsOffset6Addr,
            type(uint256).max
        );
        underlying.approve(
            ERC4626ExtendedDecimalsOffset12Addr,
            type(uint256).max
        );
        underlying.approve(
            ERC4626ExtendedDecimalsOffset18Addr,
            type(uint256).max
        );

        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.maxDeposit(holder),
            type(uint256).max
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.previewDeposit(assets), shares);

        assertEq(ERC4626ExtendedDecimalsOffset6.totalAssets(), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset6.maxDeposit(holder),
            type(uint256).max
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset6.previewDeposit(assets),
            shares * 10 ** 6
        );

        assertEq(ERC4626ExtendedDecimalsOffset12.totalAssets(), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset12.maxDeposit(holder),
            type(uint256).max
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset12.previewDeposit(assets),
            shares * 10 ** 12
        );

        assertEq(ERC4626ExtendedDecimalsOffset18.totalAssets(), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset18.maxDeposit(holder),
            type(uint256).max
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset18.previewDeposit(assets),
            shares * 10 ** 18
        );

        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(holder, ERC4626ExtendedDecimalsOffset0Addr, assets);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Transfer(zeroAddress, receiver, shares);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Deposit(holder, receiver, assets, shares);
        ERC4626ExtendedDecimalsOffset0.deposit(assets, receiver);

        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(holder, ERC4626ExtendedDecimalsOffset6Addr, assets);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset6Addr
        );
        emit Transfer(zeroAddress, receiver, shares * 10 ** 6);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset6Addr
        );
        emit Deposit(holder, receiver, assets, shares * 10 ** 6);
        ERC4626ExtendedDecimalsOffset6.deposit(assets, receiver);

        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(holder, ERC4626ExtendedDecimalsOffset12Addr, assets);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset12Addr
        );
        emit Transfer(zeroAddress, receiver, shares * 10 ** 12);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset12Addr
        );
        emit Deposit(holder, receiver, assets, shares * 10 ** 12);
        ERC4626ExtendedDecimalsOffset12.deposit(assets, receiver);

        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(holder, ERC4626ExtendedDecimalsOffset18Addr, assets);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset18Addr
        );
        emit Transfer(zeroAddress, receiver, shares * 10 ** 18);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset18Addr
        );
        emit Deposit(holder, receiver, assets, shares * 10 ** 18);
        ERC4626ExtendedDecimalsOffset18.deposit(assets, receiver);

        assertEq(underlying.balanceOf(holder), type(uint16).max - 4);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), assets);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(receiver), shares);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), shares);

        assertEq(ERC4626ExtendedDecimalsOffset6.totalAssets(), assets);
        assertEq(ERC4626ExtendedDecimalsOffset6.balanceOf(holder), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset6.balanceOf(receiver),
            shares * 10 ** 6
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset6.totalSupply(),
            shares * 10 ** 6
        );

        assertEq(ERC4626ExtendedDecimalsOffset12.totalAssets(), assets);
        assertEq(ERC4626ExtendedDecimalsOffset12.balanceOf(holder), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset12.balanceOf(receiver),
            shares * 10 ** 12
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset12.totalSupply(),
            shares * 10 ** 12
        );

        assertEq(ERC4626ExtendedDecimalsOffset18.totalAssets(), assets);
        assertEq(ERC4626ExtendedDecimalsOffset18.balanceOf(holder), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset18.balanceOf(receiver),
            shares * 10 ** 18
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset18.totalSupply(),
            shares * 10 ** 18
        );
        vm.stopPrank();
    }
}
