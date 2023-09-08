// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {ERC4626Test} from "erc4626-tests/ERC4626.test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20Errors} from "openzeppelin/interfaces/draft-IERC6093.sol";

import {ERC20Mock} from "../utils/mocks/ERC20Mock.sol";
import {ERC20ExcessDecimalsMock} from "./mocks/ERC20ExcessDecimalsMock.sol";

import {IERC4626Extended} from "./interfaces/IERC4626Extended.sol";

contract ERC4626VaultTest is ERC4626Test {
    string private constant _NAME = "TokenisedVaultMock";
    string private constant _NAME_UNDERLYING = "UnderlyingTokenMock";
    string private constant _SYMBOL = "TVM";
    string private constant _SYMBOL_UNDERLYING = "UTM";
    string private constant _NAME_EIP712 = "TokenisedVaultMock";
    string private constant _VERSION_EIP712 = "1";
    uint8 private constant _DECIMALS_OFFSET = 0;
    uint256 private constant _INITIAL_SUPPLY_UNDERLYING = type(uint8).max;
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
            _INITIAL_SUPPLY_UNDERLYING
        );

    /* solhint-disable var-name-mixedcase */
    IERC4626Extended private ERC4626ExtendedDecimalsOffset0;
    IERC4626Extended private ERC4626ExtendedDecimalsOffset6;
    IERC4626Extended private ERC4626ExtendedDecimalsOffset12;
    IERC4626Extended private ERC4626ExtendedDecimalsOffset18;
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    /* solhint-enable var-name-mixedcase */

    address private deployer = address(vyperDeployer);
    address private self = address(this);
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

        /**
         * @dev Check the case where the return value is above the
         * maximum value of the type `uint8`.
         */
        address erc20ExcessDecimalsMock = address(
            new ERC20ExcessDecimalsMock()
        );
        bytes memory argsDecimalsOffsetTooHighDecimals = abi.encode(
            _NAME,
            _SYMBOL,
            erc20ExcessDecimalsMock,
            _DECIMALS_OFFSET + 9,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        // solhint-disable-next-line var-name-mixedcase
        IERC4626Extended ERC4626ExtendedDecimalsOffsetTooHighDecimals = IERC4626Extended(
                vyperDeployer.deployContract(
                    "src/extensions/",
                    "ERC4626",
                    argsDecimalsOffsetTooHighDecimals
                )
            );
        assertEq(ERC4626ExtendedDecimalsOffsetTooHighDecimals.name(), _NAME);
        assertEq(
            ERC4626ExtendedDecimalsOffsetTooHighDecimals.symbol(),
            _SYMBOL
        );
        assertEq(
            ERC4626ExtendedDecimalsOffsetTooHighDecimals.decimals(),
            18 + 9
        );
        assertEq(
            ERC4626ExtendedDecimalsOffsetTooHighDecimals.asset(),
            erc20ExcessDecimalsMock
        );

        /**
         * @dev Check the case where calculated `decimals` value overflows
         * the `uint8` type.
         */
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
            false,
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
            false,
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
            false,
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
            false,
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

    function testEmptyVaultMint() public {
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
            ERC4626ExtendedDecimalsOffset0.maxMint(receiver),
            type(uint256).max
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.previewMint(shares), assets);

        assertEq(ERC4626ExtendedDecimalsOffset6.totalAssets(), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset6.maxMint(receiver),
            type(uint256).max
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset6.previewMint(shares * 10 ** 6),
            assets
        );

        assertEq(ERC4626ExtendedDecimalsOffset12.totalAssets(), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset12.maxMint(receiver),
            type(uint256).max
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset12.previewMint(shares * 10 ** 12),
            assets
        );

        assertEq(ERC4626ExtendedDecimalsOffset18.totalAssets(), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset18.maxMint(receiver),
            type(uint256).max
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset18.previewMint(shares * 10 ** 18),
            assets
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
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Deposit(holder, receiver, assets, shares);
        ERC4626ExtendedDecimalsOffset0.mint(shares, receiver);

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
            false,
            true,
            ERC4626ExtendedDecimalsOffset6Addr
        );
        emit Deposit(holder, receiver, assets, shares * 10 ** 6);
        ERC4626ExtendedDecimalsOffset6.mint(shares * 10 ** 6, receiver);

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
            false,
            true,
            ERC4626ExtendedDecimalsOffset12Addr
        );
        emit Deposit(holder, receiver, assets, shares * 10 ** 12);
        ERC4626ExtendedDecimalsOffset12.mint(shares * 10 ** 12, receiver);

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
            false,
            true,
            ERC4626ExtendedDecimalsOffset18Addr
        );
        emit Deposit(holder, receiver, assets, shares * 10 ** 18);
        ERC4626ExtendedDecimalsOffset18.mint(shares * 10 ** 18, receiver);

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

    function testEmptyVaultwithdraw() public {
        address holder = makeAddr("holder");
        address receiver = makeAddr("receiver");
        vm.startPrank(holder);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.maxWithdraw(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.previewWithdraw(0), 0);

        assertEq(ERC4626ExtendedDecimalsOffset6.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.maxWithdraw(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.previewWithdraw(0), 0);

        assertEq(ERC4626ExtendedDecimalsOffset12.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.maxWithdraw(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.previewWithdraw(0), 0);

        assertEq(ERC4626ExtendedDecimalsOffset18.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.maxWithdraw(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.previewWithdraw(0), 0);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset0Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset0.withdraw(0, receiver, holder);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset6Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset6Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset6Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset6.withdraw(0, receiver, holder);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset12Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset12Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset12Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset12.withdraw(0, receiver, holder);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset18Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset18Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset18Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset18.withdraw(0, receiver, holder);

        assertEq(underlying.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 0);

        assertEq(ERC4626ExtendedDecimalsOffset6.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.totalSupply(), 0);

        assertEq(ERC4626ExtendedDecimalsOffset12.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.totalSupply(), 0);

        assertEq(ERC4626ExtendedDecimalsOffset18.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.totalSupply(), 0);
        vm.stopPrank();
    }

    function testEmptyVaultRedeem() public {
        address holder = makeAddr("holder");
        address receiver = makeAddr("receiver");
        vm.startPrank(holder);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.maxRedeem(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.previewRedeem(0), 0);

        assertEq(ERC4626ExtendedDecimalsOffset6.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.maxRedeem(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.previewRedeem(0), 0);

        assertEq(ERC4626ExtendedDecimalsOffset12.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.maxRedeem(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.previewRedeem(0), 0);

        assertEq(ERC4626ExtendedDecimalsOffset18.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.maxRedeem(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.previewRedeem(0), 0);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset0Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset0.redeem(0, receiver, holder);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset6Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset6Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset6Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset6.redeem(0, receiver, holder);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset12Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset12Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset12Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset12.redeem(0, receiver, holder);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset18Addr
        );
        emit Transfer(holder, zeroAddress, 0);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset18Addr, receiver, 0);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset18Addr
        );
        emit Withdraw(holder, receiver, holder, 0, 0);
        ERC4626ExtendedDecimalsOffset18.redeem(0, receiver, holder);

        assertEq(underlying.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 0);

        assertEq(ERC4626ExtendedDecimalsOffset6.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset6.totalSupply(), 0);

        assertEq(ERC4626ExtendedDecimalsOffset12.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset12.totalSupply(), 0);

        assertEq(ERC4626ExtendedDecimalsOffset18.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.balanceOf(holder), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.balanceOf(receiver), 0);
        assertEq(ERC4626ExtendedDecimalsOffset18.totalSupply(), 0);
        vm.stopPrank();
    }

    /**
     * @dev For the remaining tests, we only use the test contract `ERC4626ExtendedDecimalsOffset0`,
     * as we have correctly proven the decimals offset behaviour above.
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/transmissions11/solmate/blob/main/src/test/ERC4626.t.sol.
     */
    function testSingleDepositWithdraw() public {
        address alice = makeAddr("alice");
        uint256 assets = 100;
        vm.startPrank(alice);
        underlying.mint(alice, assets);
        underlying.approve(ERC4626ExtendedDecimalsOffset0Addr, assets);
        assertEq(
            underlying.allowance(alice, ERC4626ExtendedDecimalsOffset0Addr),
            assets
        );
        uint256 alicePreDepositBalance = underlying.balanceOf(alice);

        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(alice, ERC4626ExtendedDecimalsOffset0Addr, assets);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Transfer(zeroAddress, alice, assets);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Deposit(alice, alice, assets, assets);
        uint256 aliceShareAmount = ERC4626ExtendedDecimalsOffset0.deposit(
            assets,
            alice
        );

        assertEq(assets, aliceShareAmount);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.previewWithdraw(aliceShareAmount),
            assets
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.previewDeposit(assets),
            aliceShareAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.totalSupply(),
            aliceShareAmount
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), assets);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.balanceOf(alice),
            aliceShareAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            assets
        );
        assertEq(underlying.balanceOf(alice), alicePreDepositBalance - assets);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Transfer(alice, zeroAddress, assets);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset0Addr, alice, assets);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Withdraw(alice, alice, alice, assets, assets);
        ERC4626ExtendedDecimalsOffset0.withdraw(assets, alice, alice);

        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            0
        );
        assertEq(underlying.balanceOf(alice), alicePreDepositBalance);
        vm.stopPrank();
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/transmissions11/solmate/blob/main/src/test/ERC4626.t.sol.
     */
    function testSingleMintRedeem() public {
        address alice = makeAddr("alice");
        uint256 shares = 100;
        vm.startPrank(alice);
        underlying.mint(alice, shares);
        underlying.approve(ERC4626ExtendedDecimalsOffset0Addr, shares);
        assertEq(
            underlying.allowance(alice, ERC4626ExtendedDecimalsOffset0Addr),
            shares
        );
        uint256 alicePreDepositBalance = underlying.balanceOf(alice);

        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(alice, ERC4626ExtendedDecimalsOffset0Addr, shares);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Transfer(zeroAddress, alice, shares);
        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Deposit(alice, alice, shares, shares);
        uint256 aliceAssetAmount = ERC4626ExtendedDecimalsOffset0.mint(
            shares,
            alice
        );

        assertEq(aliceAssetAmount, shares);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.previewWithdraw(aliceAssetAmount),
            shares
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.previewDeposit(shares),
            aliceAssetAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.totalSupply(),
            aliceAssetAmount
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), shares);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.balanceOf(alice),
            aliceAssetAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            shares
        );
        assertEq(underlying.balanceOf(alice), alicePreDepositBalance - shares);

        vm.expectEmit(
            true,
            true,
            false,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Transfer(alice, zeroAddress, shares);
        vm.expectEmit(true, true, false, true, underlyingAddr);
        emit Transfer(ERC4626ExtendedDecimalsOffset0Addr, alice, shares);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            ERC4626ExtendedDecimalsOffset0Addr
        );
        emit Withdraw(alice, alice, alice, shares, shares);
        ERC4626ExtendedDecimalsOffset0.redeem(shares, alice, alice);

        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            0
        );
        assertEq(underlying.balanceOf(alice), alicePreDepositBalance);
        vm.stopPrank();
    }

    /**
     * @notice Forked and adjusted accordingly from here:
     * https://github.com/transmissions11/solmate/blob/main/src/test/ERC4626.t.sol.
     */
    function testMultipleMintDepositRedeemWithdraw() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        uint256 initialAmountAlice = 4_000;
        uint256 initialAmountBob = 7_001;
        uint256 mutationUnderlyingAmount = 3_000;
        vm.startPrank(alice);
        underlying.mint(alice, initialAmountAlice);
        underlying.approve(
            ERC4626ExtendedDecimalsOffset0Addr,
            initialAmountAlice
        );
        assertEq(
            underlying.allowance(alice, ERC4626ExtendedDecimalsOffset0Addr),
            initialAmountAlice
        );
        vm.stopPrank();

        vm.startPrank(bob);
        underlying.mint(bob, initialAmountBob);
        underlying.approve(
            ERC4626ExtendedDecimalsOffset0Addr,
            initialAmountBob
        );
        assertEq(
            underlying.allowance(bob, ERC4626ExtendedDecimalsOffset0Addr),
            initialAmountBob
        );
        vm.stopPrank();

        /**
         * @dev 1. Alice mints 2,000 shares (costs 2,000 tokens).
         */
        vm.startPrank(alice);
        uint256 aliceUnderlyingAmount = ERC4626ExtendedDecimalsOffset0.mint(
            2_000,
            alice
        );
        uint256 aliceShareAmount = ERC4626ExtendedDecimalsOffset0
            .previewDeposit(aliceUnderlyingAmount);
        assertEq(aliceShareAmount, 2_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.balanceOf(alice),
            aliceShareAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            aliceUnderlyingAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToShares(
                aliceUnderlyingAmount
            ),
            ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
        );
        assertEq(aliceUnderlyingAmount, 2_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.totalSupply(),
            aliceShareAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.totalAssets(),
            aliceUnderlyingAmount
        );
        vm.stopPrank();

        /**
         * @dev 2. Bob deposits 4,000 tokens (mints 4,000 shares).
         */
        vm.startPrank(bob);
        uint256 bobShareAmount = ERC4626ExtendedDecimalsOffset0.deposit(
            4_000,
            bob
        );
        uint256 bobUnderlyingAmount = ERC4626ExtendedDecimalsOffset0
            .previewWithdraw(bobShareAmount);
        assertEq(bobUnderlyingAmount, 4_000);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), bobShareAmount);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            bobUnderlyingAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToShares(bobUnderlyingAmount),
            ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
        );
        assertEq(bobShareAmount, bobUnderlyingAmount);
        uint256 preMutationShareBal = aliceShareAmount + bobShareAmount;
        uint256 preMutationBal = aliceUnderlyingAmount + bobUnderlyingAmount;
        assertEq(
            ERC4626ExtendedDecimalsOffset0.totalSupply(),
            preMutationShareBal
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), preMutationBal);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 6_000);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 6_000);
        vm.stopPrank();

        /**
         * @dev 3. Vault mutates by +3,000 tokens (simulated yield returned from strategy).
         */
        underlying.mint(
            ERC4626ExtendedDecimalsOffset0Addr,
            mutationUnderlyingAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.totalSupply(),
            preMutationShareBal
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.totalAssets(),
            preMutationBal + mutationUnderlyingAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.balanceOf(alice),
            aliceShareAmount
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            aliceUnderlyingAmount + (mutationUnderlyingAmount / 3) * 1 - 1
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), bobShareAmount);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            bobUnderlyingAmount + (mutationUnderlyingAmount / 3) * 2 - 1
        );

        /**
         * @dev 4. Alice deposits 2,000 tokens (mints 1,333 shares).
         */
        vm.startPrank(alice);
        ERC4626ExtendedDecimalsOffset0.deposit(2_000, alice);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 7_333);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 3_333);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            4_999
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), 4_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            6_000
        );
        vm.stopPrank();

        /**
         * @dev 5. Bob mints 2,000 shares (costs 3,000 assets).
         * @notice Bob's assets spent got rounded up and Alices's
         * vault assets got rounded up.
         */
        vm.startPrank(bob);
        ERC4626ExtendedDecimalsOffset0.mint(2_000, bob);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 9_333);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 3_333);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            4_999
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), 6_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            9_000
        );
        assertEq(underlying.balanceOf(alice), 0);
        assertEq(underlying.balanceOf(bob), 1);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 14_000);
        vm.stopPrank();

        /**
         * @dev 6. Vault mutates by +3,000 tokens.
         */
        underlying.mint(
            ERC4626ExtendedDecimalsOffset0Addr,
            mutationUnderlyingAmount
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 17_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            6_070
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            10_928
        );

        /**
         * @dev 7. Alice redeems 1,333 shares (2,427 assets).
         */
        vm.startPrank(alice);
        ERC4626ExtendedDecimalsOffset0.redeem(1_333, alice, alice);
        assertEq(underlying.balanceOf(alice), 2_427);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 8_000);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 14_573);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 2_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            3_643
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), 6_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            10_929
        );
        vm.stopPrank();

        /**
         * @dev 8. Bob withdraws 2,929 assets (1,608 shares).
         */
        vm.startPrank(bob);
        ERC4626ExtendedDecimalsOffset0.withdraw(2_929, bob, bob);
        assertEq(underlying.balanceOf(bob), 2_930);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 6_392);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 11_644);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 2_000);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            3_643
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), 4_392);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            8_000
        );
        vm.stopPrank();

        /**
         * @dev 9. Alice withdraws 3,643 assets (2,000 shares).
         * @notice Bob's assets have been rounded back up.
         */
        vm.startPrank(alice);
        ERC4626ExtendedDecimalsOffset0.withdraw(3_643, alice, alice);
        assertEq(underlying.balanceOf(alice), 6_070);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 4_392);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 8_001);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            0
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), 4_392);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            8_000
        );
        vm.stopPrank();

        /**
         * @dev 10. Bob redeems 4,392 shares (8,000 tokens).
         */
        vm.startPrank(bob);
        ERC4626ExtendedDecimalsOffset0.redeem(4_392, bob, bob);
        assertEq(underlying.balanceOf(bob), 10_930);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 1);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(alice)
            ),
            0
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(bob)
            ),
            0
        );
        assertEq(underlying.balanceOf(ERC4626ExtendedDecimalsOffset0Addr), 1);
        vm.stopPrank();
    }

    function testDepositInsufficientAllowance() public {
        underlying.mint(self, type(uint8).max);
        underlying.approve(
            ERC4626ExtendedDecimalsOffset0Addr,
            type(uint8).max - 1
        );
        assertEq(
            underlying.allowance(self, ERC4626ExtendedDecimalsOffset0Addr),
            type(uint8).max - 1
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                ERC4626ExtendedDecimalsOffset0Addr,
                type(uint8).max - 1,
                type(uint8).max
            )
        );
        ERC4626ExtendedDecimalsOffset0.deposit(type(uint8).max, self);
    }

    function testWithdrawInsufficientAssets() public {
        underlying.mint(self, type(uint8).max);
        underlying.approve(ERC4626ExtendedDecimalsOffset0Addr, type(uint8).max);
        ERC4626ExtendedDecimalsOffset0.deposit(type(uint8).max, self);
        vm.expectRevert(bytes("ERC4626: withdraw more than maximum"));
        ERC4626ExtendedDecimalsOffset0.withdraw(
            uint256(type(uint8).max) + 1,
            self,
            self
        );
    }

    function testWithdrawInsufficientAllowance() public {
        underlying.mint(self, type(uint8).max);
        underlying.approve(ERC4626ExtendedDecimalsOffset0Addr, type(uint8).max);
        ERC4626ExtendedDecimalsOffset0.deposit(type(uint8).max, self);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        vm.prank(makeAddr("otherAccount"));
        ERC4626ExtendedDecimalsOffset0.withdraw(type(uint8).max, self, self);
    }

    function testRedeemInsufficientShares() public {
        underlying.mint(self, type(uint16).max);
        underlying.approve(ERC4626ExtendedDecimalsOffset0Addr, type(uint8).max);
        ERC4626ExtendedDecimalsOffset0.deposit(type(uint8).max, self);
        vm.expectRevert(bytes("ERC4626: redeem more than maximum"));
        ERC4626ExtendedDecimalsOffset0.redeem(
            uint256(type(uint8).max) + 1,
            self,
            self
        );
    }

    function testWithdrawWithNoAssets() public {
        vm.expectRevert(bytes("ERC4626: withdraw more than maximum"));
        ERC4626ExtendedDecimalsOffset0.withdraw(type(uint8).max, self, self);
    }

    function testRedeemWithNoShares() public {
        vm.expectRevert(bytes("ERC4626: redeem more than maximum"));
        ERC4626ExtendedDecimalsOffset0.redeem(type(uint8).max, self, self);
    }

    function testDepositWithNoApproval() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                ERC4626ExtendedDecimalsOffset0Addr,
                0,
                type(uint8).max
            )
        );
        ERC4626ExtendedDecimalsOffset0.deposit(type(uint8).max, self);
    }

    function testMintWithNoApproval() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                ERC4626ExtendedDecimalsOffset0Addr,
                0,
                type(uint8).max
            )
        );
        ERC4626ExtendedDecimalsOffset0.mint(type(uint8).max, self);
    }

    function testDepositZero() public {
        ERC4626ExtendedDecimalsOffset0.deposit(0, self);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(self), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(self)
            ),
            0
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
    }

    function testMintZero() public {
        ERC4626ExtendedDecimalsOffset0.mint(0, self);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(self), 0);
        assertEq(
            ERC4626ExtendedDecimalsOffset0.convertToAssets(
                ERC4626ExtendedDecimalsOffset0.balanceOf(self)
            ),
            0
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.totalSupply(), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.totalAssets(), 0);
    }

    function testVaultInteractionsForSomeoneElse() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        uint256 amount = 1_000;
        underlying.mint(alice, amount);
        underlying.mint(bob, amount);

        vm.prank(alice);
        underlying.approve(ERC4626ExtendedDecimalsOffset0Addr, amount);
        vm.prank(bob);
        underlying.approve(ERC4626ExtendedDecimalsOffset0Addr, amount);

        vm.startPrank(alice);
        ERC4626ExtendedDecimalsOffset0.deposit(amount, bob);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), amount);
        assertEq(underlying.balanceOf(alice), 0);
        vm.stopPrank();

        vm.startPrank(bob);
        ERC4626ExtendedDecimalsOffset0.mint(amount, alice);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), amount);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), amount);
        assertEq(underlying.balanceOf(bob), 0);
        vm.stopPrank();

        vm.startPrank(alice);
        ERC4626ExtendedDecimalsOffset0.redeem(amount, bob, alice);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(alice), 0);
        assertEq(ERC4626ExtendedDecimalsOffset0.balanceOf(bob), amount);
        assertEq(underlying.balanceOf(bob), amount);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(bytes("ERC4626: withdraw more than maximum"));
        ERC4626ExtendedDecimalsOffset0.withdraw(amount, alice, bob);
        vm.stopPrank();
    }

    function testPermitSuccess() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC4626ExtendedDecimalsOffset0.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC4626ExtendedDecimalsOffset0
            .DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        ERC4626ExtendedDecimalsOffset0.permit(
            owner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.allowance(owner, spender),
            amount
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.nonces(owner), 1);
    }

    function testPermitReplaySignature() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC4626ExtendedDecimalsOffset0.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC4626ExtendedDecimalsOffset0
            .DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        ERC4626ExtendedDecimalsOffset0.permit(
            owner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC4626ExtendedDecimalsOffset0.permit(
            owner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function testPermitOtherSignature() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC4626ExtendedDecimalsOffset0.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC4626ExtendedDecimalsOffset0
            .DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key + 1,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC4626ExtendedDecimalsOffset0.permit(
            owner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function testPermitBadChainId() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC4626ExtendedDecimalsOffset0.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid + 1,
                ERC4626ExtendedDecimalsOffset0Addr
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC4626ExtendedDecimalsOffset0.permit(
            owner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function testPermitBadNonce() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = 1;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC4626ExtendedDecimalsOffset0
            .DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC4626ExtendedDecimalsOffset0.permit(
            owner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function testPermitExpiredDeadline() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC4626ExtendedDecimalsOffset0.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp - 1;
        bytes32 domainSeparator = ERC4626ExtendedDecimalsOffset0
            .DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: expired deadline"));
        ERC4626ExtendedDecimalsOffset0.permit(
            owner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function testCachedDomainSeparator() public {
        assertEq(
            ERC4626ExtendedDecimalsOffset0.DOMAIN_SEPARATOR(),
            _CACHED_DOMAIN_SEPARATOR
        );
    }

    function testDomainSeparator() public {
        vm.chainId(block.chainid + 1);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC4626ExtendedDecimalsOffset0Addr
            )
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.DOMAIN_SEPARATOR(), digest);
    }

    function testEIP712Domain() public {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = ERC4626ExtendedDecimalsOffset0.eip712Domain();
        assertEq(fields, hex"0f");
        assertEq(name, _NAME_EIP712);
        assertEq(version, _VERSION_EIP712);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, ERC4626ExtendedDecimalsOffset0Addr);
        assertEq(salt, bytes32(0));
        assertEq(extensions, new uint256[](0));

        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.DOMAIN_SEPARATOR(), digest);
    }

    function testFuzzPermitSuccess(
        string calldata owner,
        string calldata spender,
        uint16 increment
    ) public {
        (address ownerAddr, uint256 key) = makeAddrAndKey(owner);
        address spenderAddr = makeAddr(spender);
        uint256 amount = block.number;
        uint256 nonce = ERC4626ExtendedDecimalsOffset0.nonces(ownerAddr);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + increment;
        bytes32 domainSeparator = ERC4626ExtendedDecimalsOffset0
            .DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            ownerAddr,
                            spenderAddr,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectEmit(true, true, false, true);
        emit Approval(ownerAddr, spenderAddr, amount);
        ERC4626ExtendedDecimalsOffset0.permit(
            ownerAddr,
            spenderAddr,
            amount,
            deadline,
            v,
            r,
            s
        );
        assertEq(
            ERC4626ExtendedDecimalsOffset0.allowance(ownerAddr, spenderAddr),
            amount
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.nonces(ownerAddr), 1);
    }

    function testFuzzPermitInvalid(
        string calldata owner,
        string calldata spender,
        uint16 increment
    ) public {
        vm.assume(
            keccak256(abi.encode(owner)) != keccak256(abi.encode("ownerWrong"))
        );
        (address ownerAddr, ) = makeAddrAndKey(owner);
        (, uint256 keyWrong) = makeAddrAndKey("ownerWrong");
        address spenderAddr = makeAddr(spender);
        uint256 amount = block.number;
        uint256 nonce = ERC4626ExtendedDecimalsOffset0.nonces(ownerAddr);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + increment;
        bytes32 domainSeparator = ERC4626ExtendedDecimalsOffset0
            .DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            keyWrong,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPE_HASH,
                            ownerAddr,
                            spenderAddr,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC4626ExtendedDecimalsOffset0.permit(
            ownerAddr,
            spenderAddr,
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function testFuzzDomainSeparator(uint8 increment) public {
        vm.chainId(block.chainid + increment);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC4626ExtendedDecimalsOffset0Addr
            )
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.DOMAIN_SEPARATOR(), digest);
    }

    function testFuzzEIP712Domain(
        bytes1 randomHex,
        uint8 increment,
        bytes32 randomSalt,
        uint256[] calldata randomExtensions
    ) public {
        vm.assume(
            randomHex != hex"0f" &&
                randomSalt != bytes32(0) &&
                randomExtensions.length != 0
        );
        vm.chainId(block.chainid + increment);
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = ERC4626ExtendedDecimalsOffset0.eip712Domain();
        assertTrue(fields != randomHex);
        assertEq(name, _NAME_EIP712);
        assertEq(version, _VERSION_EIP712);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, ERC4626ExtendedDecimalsOffset0Addr);
        assertTrue(salt != randomSalt);
        assertTrue(
            keccak256(abi.encode(extensions)) !=
                keccak256(abi.encode(randomExtensions))
        );

        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
        assertEq(ERC4626ExtendedDecimalsOffset0.DOMAIN_SEPARATOR(), digest);
    }
}

contract ERC4626VaultInvariants is Test {
    string private constant _NAME = "TokenisedVaultMock";
    string private constant _NAME_UNDERLYING = "UnderlyingTokenMock";
    string private constant _SYMBOL = "TVM";
    string private constant _SYMBOL_UNDERLYING = "UTM";
    string private constant _NAME_EIP712 = "TokenisedVaultMock";
    string private constant _VERSION_EIP712 = "1";
    uint8 private constant _DECIMALS_OFFSET = 9;
    uint256 private constant _INITIAL_SUPPLY_UNDERLYING = type(uint8).max;

    VyperDeployer private vyperDeployer = new VyperDeployer();
    address private deployer = address(vyperDeployer);
    ERC20Mock private underlying =
        new ERC20Mock(
            _NAME_UNDERLYING,
            _SYMBOL_UNDERLYING,
            deployer,
            _INITIAL_SUPPLY_UNDERLYING
        );

    // solhint-disable-next-line var-name-mixedcase
    IERC4626Extended private ERC4626Extended;
    ERC4626VaultHandler private erc4626VaultHandler;

    function setUp() public {
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
        erc4626VaultHandler = new ERC4626VaultHandler(ERC4626Extended);
        targetContract(address(erc4626VaultHandler));
        targetSender(deployer);
    }

    function invariantTotalSupply() public {
        assertEq(
            ERC4626Extended.totalSupply(),
            erc4626VaultHandler.totalSupply()
        );
    }

    function invariantTotalAssets() public {
        assertEq(
            ERC4626Extended.totalAssets(),
            erc4626VaultHandler.totalAssets()
        );
    }
}

contract ERC4626VaultHandler {
    uint256 public totalSupply;
    uint256 public totalAssets;

    IERC4626Extended private vault;

    constructor(IERC4626Extended vault_) {
        vault = vault_;
    }

    function transfer(address to, uint256 amount) public {
        vault.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) public {
        vault.approve(spender, amount);
    }

    function transferFrom(address owner, address to, uint256 amount) public {
        vault.transferFrom(owner, to, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        vault.permit(owner, spender, value, deadline, v, r, s);
    }

    function deposit(uint256 assets, address receiver) public {
        uint256 shares = vault.deposit(assets, receiver);
        totalSupply += shares;
        totalAssets += assets;
    }

    function mint(uint256 shares, address receiver) public {
        uint256 assets = vault.mint(shares, receiver);
        totalSupply += shares;
        totalAssets += assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public {
        uint256 shares = vault.withdraw(assets, receiver, owner);
        totalSupply -= shares;
        totalAssets -= assets;
    }

    function redeem(uint256 shares, address receiver, address owner) public {
        uint256 assets = vault.redeem(shares, receiver, owner);
        totalSupply -= shares;
        totalAssets -= assets;
    }
}
