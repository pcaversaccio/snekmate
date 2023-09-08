// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IERC20Extended} from "./interfaces/IERC20Extended.sol";

contract ERC20Test is Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "WAGMI";
    string private constant _NAME_EIP712 = "MyToken";
    string private constant _VERSION_EIP712 = "1";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;
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

    /* solhint-disable var-name-mixedcase */
    IERC20Extended private ERC20Extended;
    IERC20Extended private ERC20ExtendedInitialEvent;
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    /* solhint-enable var-name-mixedcase */

    address private deployer = address(vyperDeployer);
    address private self = address(this);
    address private zeroAddress = address(0);
    // solhint-disable-next-line var-name-mixedcase
    address private ERC20ExtendedAddr;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event RoleMinterChanged(address indexed minter, bool status);

    function setUp() public {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _INITIAL_SUPPLY,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC20Extended = IERC20Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC20", args)
        );
        ERC20ExtendedAddr = address(ERC20Extended);
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC20ExtendedAddr
            )
        );
    }

    function testInitialSetup() public {
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
        assertEq(ERC20Extended.decimals(), 18);
        assertEq(ERC20Extended.name(), _NAME);
        assertEq(ERC20Extended.symbol(), _SYMBOL);
        assertEq(ERC20Extended.totalSupply(), _INITIAL_SUPPLY * multiplier);
        assertEq(
            ERC20Extended.balanceOf(deployer),
            _INITIAL_SUPPLY * multiplier
        );
        assertEq(ERC20Extended.owner(), deployer);
        assertTrue(ERC20Extended.is_minter(deployer));

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(zeroAddress, deployer);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(deployer, true);
        vm.expectEmit(true, true, false, true);
        emit Transfer(zeroAddress, deployer, _INITIAL_SUPPLY * multiplier);
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _INITIAL_SUPPLY,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC20ExtendedInitialEvent = IERC20Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC20", args)
        );
        assertEq(ERC20ExtendedInitialEvent.decimals(), 18);
        assertEq(ERC20ExtendedInitialEvent.name(), _NAME);
        assertEq(ERC20ExtendedInitialEvent.symbol(), _SYMBOL);
        assertEq(
            ERC20ExtendedInitialEvent.totalSupply(),
            _INITIAL_SUPPLY * multiplier
        );
        assertEq(
            ERC20ExtendedInitialEvent.balanceOf(deployer),
            _INITIAL_SUPPLY * multiplier
        );
        assertEq(ERC20ExtendedInitialEvent.owner(), deployer);
        assertTrue(ERC20ExtendedInitialEvent.is_minter(deployer));
    }

    function testTotalSupply() public {
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
        assertEq(ERC20Extended.totalSupply(), _INITIAL_SUPPLY * multiplier);
    }

    function testBalanceOf() public {
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
        assertEq(
            ERC20Extended.balanceOf(deployer),
            _INITIAL_SUPPLY * multiplier
        );
        assertEq(ERC20Extended.balanceOf(makeAddr("account")), 0);
    }

    function testTransferSuccess() public {
        address owner = deployer;
        address to = makeAddr("to");
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transfer(to, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.balanceOf(owner), 0);
        assertEq(ERC20Extended.balanceOf(to), amount);
        vm.stopPrank();
    }

    function testTransferInvalidAmount() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        ERC20Extended.transfer(makeAddr("to"), type(uint256).max);
    }

    function testTransferZeroTokens() public {
        address owner = deployer;
        address to = makeAddr("to");
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 amount = 0;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transfer(to, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.balanceOf(owner), balance);
        assertEq(ERC20Extended.balanceOf(to), amount);
        vm.stopPrank();
    }

    function testTransferToZeroAddress() public {
        address owner = deployer;
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: transfer to the zero address"));
        ERC20Extended.transfer(zeroAddress, amount);
    }

    function testTransferFromZeroAddress() public {
        address owner = deployer;
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.burn(amount);
        vm.prank(zeroAddress);
        vm.expectRevert(bytes("ERC20: transfer from the zero address"));
        ERC20Extended.transfer(makeAddr("to"), amount);
    }

    function testApproveSuccessCase1() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue = ERC20Extended.approve(spender, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.allowance(owner, spender), amount);
        vm.stopPrank();
    }

    function testApproveSuccessCase2() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 firstAmount = 100;
        uint256 secondAmount = ERC20Extended.balanceOf(owner);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, firstAmount);
        bool returnValue1 = ERC20Extended.approve(spender, firstAmount);
        assertEq(ERC20Extended.allowance(owner, spender), firstAmount);
        assertTrue(returnValue1);

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, secondAmount);
        bool returnValue2 = ERC20Extended.approve(spender, secondAmount);
        assertTrue(returnValue2);
        assertEq(ERC20Extended.allowance(owner, spender), secondAmount);
        vm.stopPrank();
    }

    function testApproveExceedingBalanceCase1() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = type(uint128).max;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue = ERC20Extended.approve(spender, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.allowance(owner, spender), amount);
        vm.stopPrank();
    }

    function testApproveExceedingBalanceCase2() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 firstAmount = 100;
        uint256 secondAmount = type(uint128).max;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, firstAmount);
        bool returnValue1 = ERC20Extended.approve(spender, firstAmount);
        assertEq(ERC20Extended.allowance(owner, spender), firstAmount);
        assertTrue(returnValue1);

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, secondAmount);
        bool returnValue2 = ERC20Extended.approve(spender, secondAmount);
        assertTrue(returnValue2);
        assertEq(ERC20Extended.allowance(owner, spender), secondAmount);
        vm.stopPrank();
    }

    function testApproveToZeroAddress() public {
        address owner = deployer;
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: approve to the zero address"));
        ERC20Extended.approve(zeroAddress, amount);
    }

    function testApproveFromZeroAddress() public {
        vm.prank(zeroAddress);
        vm.expectRevert(bytes("ERC20: approve from the zero address"));
        ERC20Extended.approve(makeAddr("spender"), type(uint256).max);
    }

    function testTransferFromSuccess() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        address to = makeAddr("to");
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(
            owner,
            spender,
            ERC20Extended.allowance(owner, spender) - amount
        );
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transferFrom(owner, to, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.balanceOf(owner), 0);
        assertEq(ERC20Extended.balanceOf(to), amount);
        assertEq(ERC20Extended.allowance(owner, spender), 0);
        vm.stopPrank();
    }

    function testTransferFromExceedingBalance() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        ERC20Extended.transferFrom(owner, makeAddr("to"), amount);
    }

    function testTransferFromInsufficientAllowanceCase1() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.transferFrom(owner, makeAddr("to"), amount);
    }

    function testTransferFromInsufficientAllowanceCase2() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.transferFrom(owner, makeAddr("to"), amount);
    }

    function testTransferFromUnlimitedAllowance() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        address to = makeAddr("to");
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, type(uint256).max);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);

        bool returnValue = ERC20Extended.transferFrom(owner, to, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.balanceOf(owner), 0);
        assertEq(ERC20Extended.balanceOf(to), amount);
        assertEq(ERC20Extended.allowance(owner, spender), type(uint256).max);
        vm.stopPrank();
    }

    function testTransferFromToZeroAddress() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: transfer to the zero address"));
        ERC20Extended.transferFrom(owner, zeroAddress, amount);
    }

    function testTransferFromFromZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("ERC20: approve from the zero address"));
        ERC20Extended.transferFrom(zeroAddress, makeAddr("to"), 0);
    }

    function testBurnSuccessCase1() public {
        address owner = deployer;
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        uint256 amount = 0;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, zeroAddress, amount);
        ERC20Extended.burn(amount);
        assertEq(ERC20Extended.balanceOf(owner), balance - amount);
        assertEq(ERC20Extended.totalSupply(), totalSupply - amount);
        vm.stopPrank();
    }

    function testBurnSuccessCase2() public {
        address owner = deployer;
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        uint256 amount = 100;
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, zeroAddress, amount);
        ERC20Extended.burn(amount);
        assertEq(ERC20Extended.balanceOf(owner), balance - amount);
        assertEq(ERC20Extended.totalSupply(), totalSupply - amount);
        vm.stopPrank();
    }

    function testBurnInvalidAmount() public {
        address owner = deployer;
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 amount = balance + 1;
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        ERC20Extended.burn(amount);
    }

    function testBurnFromZeroAddress() public {
        vm.prank(zeroAddress);
        vm.expectRevert(bytes("ERC20: burn from the zero address"));
        ERC20Extended.burn(0);
    }

    function testBurnFromSuccessCase1() public {
        address owner = deployer;
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        address spender = makeAddr("spender");
        uint256 amount = 0;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(
            owner,
            spender,
            ERC20Extended.allowance(owner, spender) - amount
        );

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, zeroAddress, amount);
        ERC20Extended.burn_from(owner, amount);
        assertEq(ERC20Extended.balanceOf(owner), balance - amount);
        assertEq(ERC20Extended.totalSupply(), totalSupply - amount);
        assertEq(ERC20Extended.allowance(owner, spender), 0);
        vm.stopPrank();
    }

    function testBurnFromSuccessCase2() public {
        address owner = deployer;
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        address spender = makeAddr("spender");
        uint256 amount = 100;
        vm.prank(owner);
        ERC20Extended.approve(spender, balance);
        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(
            owner,
            spender,
            ERC20Extended.allowance(owner, spender) - amount
        );

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, zeroAddress, amount);
        ERC20Extended.burn_from(owner, amount);
        assertEq(ERC20Extended.balanceOf(owner), balance - amount);
        assertEq(ERC20Extended.totalSupply(), totalSupply - amount);
        assertEq(ERC20Extended.allowance(owner, spender), balance - amount);
        vm.stopPrank();
    }

    function testBurnFromExceedingBalance() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        ERC20Extended.burn_from(owner, amount);
    }

    function testBurnFromInsufficientAllowanceCase1() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner);
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.burn_from(owner, amount);
    }

    function testBurnFromInsufficientAllowanceCase2() public {
        address owner = deployer;
        address spender = makeAddr("spender");
        uint256 amount = ERC20Extended.balanceOf(owner) + 1;
        vm.prank(owner);
        ERC20Extended.approve(spender, amount - 1);
        vm.prank(spender);
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.burn_from(owner, amount);
    }

    function testBurnFromUnlimitedAllowance() public {
        address owner = deployer;
        uint256 balance = ERC20Extended.balanceOf(owner);
        uint256 totalSupply = ERC20Extended.totalSupply();
        address spender = makeAddr("spender");
        uint256 amount = balance;
        vm.prank(owner);
        ERC20Extended.approve(spender, type(uint256).max);

        vm.startPrank(spender);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, zeroAddress, amount);
        ERC20Extended.burn_from(owner, amount);
        assertEq(ERC20Extended.balanceOf(owner), balance - amount);
        assertEq(ERC20Extended.totalSupply(), totalSupply - amount);
        assertEq(ERC20Extended.allowance(owner, spender), type(uint256).max);
        vm.stopPrank();
    }

    function testBurnFromFromZeroAddress() public {
        vm.prank(zeroAddress);
        vm.expectRevert(bytes("ERC20: approve to the zero address"));
        ERC20Extended.burn_from(makeAddr("owner"), 0);
    }

    function testMintSuccess() public {
        address minter = deployer;
        address owner = makeAddr("owner");
        uint256 amount = type(uint8).max;
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
        vm.startPrank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(zeroAddress, owner, amount);
        ERC20Extended.mint(owner, amount);
        assertEq(ERC20Extended.balanceOf(owner), amount);
        assertEq(
            ERC20Extended.totalSupply(),
            (amount + _INITIAL_SUPPLY * multiplier)
        );
        vm.stopPrank();
    }

    function testMintNonMinter() public {
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC20Extended.mint(makeAddr("owner"), 100);
    }

    function testMintToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        ERC20Extended.mint(zeroAddress, 100);
    }

    function testMintOverflow() public {
        vm.prank(deployer);
        vm.expectRevert();
        ERC20Extended.mint(makeAddr("owner"), type(uint256).max);
    }

    function testSetMinterSuccess() public {
        address owner = deployer;
        address minter = makeAddr("minter");
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, true);
        ERC20Extended.set_minter(minter, true);
        assertTrue(ERC20Extended.is_minter(minter));

        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minter, false);
        ERC20Extended.set_minter(minter, false);
        assertTrue(!ERC20Extended.is_minter(minter));
        vm.stopPrank();
    }

    function testSetMinterNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC20Extended.set_minter(makeAddr("minter"), true);
    }

    function testSetMinterToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("AccessControl: minter is the zero address"));
        ERC20Extended.set_minter(zeroAddress, true);
    }

    function testSetMinterRemoveOwnerAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("AccessControl: minter is owner address"));
        ERC20Extended.set_minter(deployer, false);
    }

    function testPermitSuccess() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
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
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
        assertEq(ERC20Extended.allowance(owner, spender), amount);
        assertEq(ERC20Extended.nonces(owner), 1);
    }

    function testPermitReplaySignature() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
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
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
        vm.expectRevert(bytes("ERC20Permit: invalid signature"));
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitOtherSignature() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
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
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitBadChainId() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid + 1,
                ERC20ExtendedAddr
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
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitBadNonce() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = 1;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
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
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testPermitExpiredDeadline() public {
        (address owner, uint256 key) = makeAddrAndKey("owner");
        address spender = makeAddr("spender");
        uint256 amount = 100;
        uint256 nonce = ERC20Extended.nonces(owner);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp - 1;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
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
        ERC20Extended.permit(owner, spender, amount, deadline, v, r, s);
    }

    function testCachedDomainSeparator() public {
        assertEq(ERC20Extended.DOMAIN_SEPARATOR(), _CACHED_DOMAIN_SEPARATOR);
    }

    function testDomainSeparator() public {
        vm.chainId(block.chainid + 1);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC20ExtendedAddr
            )
        );
        assertEq(ERC20Extended.DOMAIN_SEPARATOR(), digest);
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
        ) = ERC20Extended.eip712Domain();
        assertEq(fields, hex"0f");
        assertEq(name, _NAME_EIP712);
        assertEq(version, _VERSION_EIP712);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, ERC20ExtendedAddr);
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
        assertEq(ERC20Extended.DOMAIN_SEPARATOR(), digest);
    }

    function testHasOwner() public {
        assertEq(ERC20Extended.owner(), deployer);
    }

    function testTransferOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = makeAddr("newOwner");
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner, true);
        ERC20Extended.transfer_ownership(newOwner);
        assertEq(ERC20Extended.owner(), newOwner);
        assertTrue(!ERC20Extended.is_minter(oldOwner));
        assertTrue(ERC20Extended.is_minter(newOwner));
        vm.stopPrank();
    }

    function testTransferOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC20Extended.transfer_ownership(makeAddr("newOwner"));
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(bytes("Ownable: new owner is the zero address"));
        ERC20Extended.transfer_ownership(zeroAddress);
    }

    function testRenounceOwnershipSuccess() public {
        address oldOwner = deployer;
        address newOwner = zeroAddress;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        ERC20Extended.renounce_ownership();
        assertEq(ERC20Extended.owner(), newOwner);
        assertTrue(!ERC20Extended.is_minter(oldOwner));
        vm.stopPrank();
    }

    function testRenounceOwnershipNonOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC20Extended.renounce_ownership();
    }

    function testFuzzTransferSuccess(address to, uint256 amount) public {
        address from = self;
        vm.assume(to != zeroAddress && to != from && to != deployer);
        uint256 give = type(uint256).max;
        deal(ERC20ExtendedAddr, from, give);
        vm.expectEmit(true, true, false, true);
        emit Transfer(from, to, amount);
        bool returnValue = ERC20Extended.transfer(to, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.balanceOf(from), give - amount);
        assertEq(ERC20Extended.balanceOf(to), amount);
    }

    function testFuzzTransferInvalidAmount(
        address owner,
        address to,
        uint256 amount
    ) public {
        vm.assume(
            owner != deployer &&
                owner != zeroAddress &&
                to != zeroAddress &&
                amount != 0
        );
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        ERC20Extended.transfer(to, amount);
    }

    function testFuzzApproveSuccess(address spender, uint256 amount) public {
        vm.assume(spender != zeroAddress);
        address owner = self;
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        bool returnValue = ERC20Extended.approve(spender, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.allowance(owner, spender), amount);
    }

    function testFuzzTransferFromSuccess(
        address owner,
        address to,
        uint256 amount
    ) public {
        address spender = self;
        vm.assume(
            to != zeroAddress &&
                owner != zeroAddress &&
                owner != to &&
                to != spender &&
                to != deployer
        );
        amount = bound(amount, 0, type(uint64).max);
        uint256 give = type(uint256).max;
        deal(ERC20ExtendedAddr, owner, give);
        vm.startPrank(owner);
        ERC20Extended.approve(spender, amount);
        vm.stopPrank();

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, 0);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, to, amount);
        bool returnValue = ERC20Extended.transferFrom(owner, to, amount);
        assertTrue(returnValue);
        assertEq(ERC20Extended.balanceOf(owner), give - amount);
        assertEq(ERC20Extended.balanceOf(to), amount);
        assertEq(ERC20Extended.allowance(owner, spender), 0);
    }

    function testFuzzTransferFromInsufficientAllowance(
        address owner,
        address to,
        uint256 amount,
        uint8 increment
    ) public {
        address spender = self;
        vm.assume(to != zeroAddress && owner != zeroAddress && increment != 0);
        amount = bound(amount, 0, type(uint64).max);
        uint256 give = type(uint256).max;
        deal(ERC20ExtendedAddr, owner, give);
        vm.startPrank(owner);
        ERC20Extended.approve(spender, amount);
        vm.stopPrank();

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.transferFrom(owner, to, amount + increment);
    }

    function testFuzzBurnSuccessCase(uint256 amount) public {
        amount = bound(amount, 0, type(uint64).max);
        address owner = self;
        uint256 give = type(uint128).max;
        deal(ERC20ExtendedAddr, owner, give, true);
        uint256 totalSupply = ERC20Extended.totalSupply();
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, zeroAddress, amount);
        ERC20Extended.burn(amount);
        assertEq(ERC20Extended.balanceOf(owner), give - amount);
        assertEq(ERC20Extended.totalSupply(), totalSupply - amount);
        vm.stopPrank();
    }

    function testFuzzBurnInvalidAmount(address owner, uint256 amount) public {
        vm.assume(owner != deployer && owner != zeroAddress && amount != 0);
        vm.prank(owner);
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        ERC20Extended.burn(amount);
    }

    function testFuzzBurnFromSuccess(address owner, uint256 amount) public {
        vm.assume(owner != zeroAddress && owner != deployer);
        address spender = self;
        amount = bound(amount, 0, type(uint64).max);
        uint256 give = type(uint128).max;
        deal(ERC20ExtendedAddr, owner, give, true);
        uint256 totalSupply = ERC20Extended.totalSupply();
        vm.startPrank(owner);
        ERC20Extended.approve(spender, amount);
        vm.stopPrank();

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, zeroAddress, amount);
        ERC20Extended.burn_from(owner, amount);
        assertEq(ERC20Extended.balanceOf(owner), give - amount);
        assertEq(ERC20Extended.totalSupply(), totalSupply - amount);
        assertEq(ERC20Extended.allowance(owner, spender), 0);
    }

    function testFuzzBurnFromInsufficientAllowance(
        address owner,
        uint256 amount,
        uint8 increment
    ) public {
        vm.assume(owner != zeroAddress && owner != deployer && increment != 0);
        address spender = self;
        amount = bound(amount, 0, type(uint64).max);
        uint256 give = type(uint256).max;
        deal(ERC20ExtendedAddr, owner, give);
        vm.startPrank(owner);
        ERC20Extended.approve(spender, amount);
        vm.stopPrank();

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        ERC20Extended.burn_from(owner, amount + increment);
    }

    function testFuzzMintSuccess(string calldata owner, uint256 amount) public {
        address minter = deployer;
        address ownerAddr = makeAddr(owner);
        amount = bound(amount, 0, type(uint64).max);
        uint256 multiplier = 10 ** uint256(ERC20Extended.decimals());
        vm.startPrank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(zeroAddress, ownerAddr, amount);
        ERC20Extended.mint(ownerAddr, amount);
        assertEq(ERC20Extended.balanceOf(ownerAddr), amount);
        assertEq(
            ERC20Extended.totalSupply(),
            (amount + _INITIAL_SUPPLY * multiplier)
        );
        vm.stopPrank();
    }

    function testFuzzMintNonMinter(
        string calldata owner,
        uint256 amount
    ) public {
        vm.expectRevert(bytes("AccessControl: access is denied"));
        ERC20Extended.mint(makeAddr(owner), amount);
    }

    function testFuzzSetMinterSuccess(string calldata minter) public {
        address owner = deployer;
        address minterAddr = makeAddr(minter);
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minterAddr, true);
        ERC20Extended.set_minter(minterAddr, true);
        assertTrue(ERC20Extended.is_minter(minterAddr));

        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(minterAddr, false);
        ERC20Extended.set_minter(minterAddr, false);
        assertTrue(!ERC20Extended.is_minter(minterAddr));
        vm.stopPrank();
    }

    function testFuzzSetMinterNonOwner(
        address msgSender,
        string calldata minter
    ) public {
        vm.assume(msgSender != deployer);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC20Extended.set_minter(makeAddr(minter), true);
    }

    function testFuzzPermitSuccess(
        string calldata owner,
        string calldata spender,
        uint16 increment
    ) public {
        (address ownerAddr, uint256 key) = makeAddrAndKey(owner);
        address spenderAddr = makeAddr(spender);
        uint256 amount = block.number;
        uint256 nonce = ERC20Extended.nonces(ownerAddr);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + increment;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
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
        ERC20Extended.permit(ownerAddr, spenderAddr, amount, deadline, v, r, s);
        assertEq(ERC20Extended.allowance(ownerAddr, spenderAddr), amount);
        assertEq(ERC20Extended.nonces(ownerAddr), 1);
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
        uint256 nonce = ERC20Extended.nonces(ownerAddr);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + increment;
        bytes32 domainSeparator = ERC20Extended.DOMAIN_SEPARATOR();
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
        ERC20Extended.permit(ownerAddr, spenderAddr, amount, deadline, v, r, s);
    }

    function testFuzzDomainSeparator(uint8 increment) public {
        vm.chainId(block.chainid + increment);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                ERC20ExtendedAddr
            )
        );
        assertEq(ERC20Extended.DOMAIN_SEPARATOR(), digest);
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
        ) = ERC20Extended.eip712Domain();
        assertTrue(fields != randomHex);
        assertEq(name, _NAME_EIP712);
        assertEq(version, _VERSION_EIP712);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, ERC20ExtendedAddr);
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
        assertEq(ERC20Extended.DOMAIN_SEPARATOR(), digest);
    }

    function testFuzzTransferOwnershipSuccess(
        address newOwner1,
        address newOwner2
    ) public {
        vm.assume(
            newOwner1 != zeroAddress &&
                newOwner1 != deployer &&
                newOwner1 != newOwner2 &&
                newOwner2 != zeroAddress
        );
        address oldOwner = deployer;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner1);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner1, true);
        ERC20Extended.transfer_ownership(newOwner1);
        assertEq(ERC20Extended.owner(), newOwner1);
        assertTrue(!ERC20Extended.is_minter(oldOwner));
        assertTrue(ERC20Extended.is_minter(newOwner1));
        vm.stopPrank();

        vm.startPrank(newOwner1);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner1, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(newOwner1, newOwner2);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner2, true);
        emit OwnershipTransferred(newOwner1, newOwner2);
        ERC20Extended.transfer_ownership(newOwner2);
        assertEq(ERC20Extended.owner(), newOwner2);
        assertTrue(!ERC20Extended.is_minter(newOwner1));
        assertTrue(ERC20Extended.is_minter(newOwner2));
        vm.stopPrank();
    }

    function testFuzzTransferOwnershipNonOwner(
        address nonOwner,
        address newOwner
    ) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC20Extended.transfer_ownership(newOwner);
    }

    function testFuzzRenounceOwnershipSuccess(address newOwner) public {
        vm.assume(newOwner != zeroAddress);
        address oldOwner = deployer;
        address renounceAddress = zeroAddress;
        vm.startPrank(oldOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(oldOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(oldOwner, newOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner, true);
        ERC20Extended.transfer_ownership(newOwner);
        vm.stopPrank();

        vm.startPrank(newOwner);
        vm.expectEmit(true, false, false, true);
        emit RoleMinterChanged(newOwner, false);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(newOwner, renounceAddress);
        ERC20Extended.renounce_ownership();
        assertEq(ERC20Extended.owner(), renounceAddress);
        vm.stopPrank();
    }

    function testFuzzRenounceOwnershipNonOwner(address nonOwner) public {
        vm.assume(nonOwner != deployer);
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ERC20Extended.renounce_ownership();
    }
}

contract ERC20Invariants is Test {
    string private constant _NAME = "MyToken";
    string private constant _SYMBOL = "WAGMI";
    string private constant _NAME_EIP712 = "MyToken";
    string private constant _VERSION_EIP712 = "1";
    uint256 private constant _INITIAL_SUPPLY = type(uint8).max;

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC20Extended private ERC20Extended;
    ERC20Handler private erc20Handler;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        bytes memory args = abi.encode(
            _NAME,
            _SYMBOL,
            _INITIAL_SUPPLY,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC20Extended = IERC20Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC20", args)
        );
        erc20Handler = new ERC20Handler(
            ERC20Extended,
            _INITIAL_SUPPLY,
            deployer
        );
        targetContract(address(erc20Handler));
        targetSender(deployer);
    }

    function invariantTotalSupply() public {
        assertEq(ERC20Extended.totalSupply(), erc20Handler.totalSupply());
    }

    function invariantOwner() public {
        assertEq(ERC20Extended.owner(), erc20Handler.owner());
    }
}

contract ERC20Handler {
    address public owner;
    uint256 public totalSupply;

    IERC20Extended private token;

    address private zeroAddress = address(0);

    constructor(IERC20Extended token_, uint256 initialSupply_, address owner_) {
        token = token_;
        totalSupply = initialSupply_ * 10 ** uint256(token.decimals());
        owner = owner_;
    }

    function transfer(address to, uint256 amount) public {
        token.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) public {
        token.approve(spender, amount);
    }

    function transferFrom(
        address ownerAddr,
        address to,
        uint256 amount
    ) public {
        token.transferFrom(ownerAddr, to, amount);
    }

    function permit(
        address ownerAddr,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(ownerAddr, spender, value, deadline, v, r, s);
    }

    function burn(uint256 amount) public {
        token.burn(amount);
        totalSupply -= amount;
    }

    function burn_from(address ownerAddr, uint256 amount) public {
        token.burn_from(ownerAddr, amount);
        totalSupply -= amount;
    }

    function mint(address ownerAddr, uint256 amount) public {
        token.mint(ownerAddr, amount);
        totalSupply += amount;
    }

    function set_minter(address minter, bool status) public {
        token.set_minter(minter, status);
    }

    function transfer_ownership(address newOwner) public {
        token.transfer_ownership(newOwner);
        owner = newOwner;
    }

    function renounce_ownership() public {
        token.renounce_ownership();
        owner = zeroAddress;
    }
}
