// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IEIP712DomainSeparator} from "./interfaces/IEIP712DomainSeparator.sol";

contract EIP712DomainSeparatorTest is Test {
    string private constant _NAME = "WAGMI";
    string private constant _VERSION = "1";
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

    // solhint-disable-next-line var-name-mixedcase
    IEIP712DomainSeparator private EIP712domainSeparator;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _CACHED_DOMAIN_SEPARATOR;

    // solhint-disable-next-line var-name-mixedcase
    address private EIP712domainSeparatorAddr;

    function setUp() public {
        bytes memory args = abi.encode(_NAME, _VERSION);
        EIP712domainSeparator = IEIP712DomainSeparator(
            vyperDeployer.deployContract(
                "src/utils/",
                "EIP712DomainSeparator",
                args
            )
        );
        EIP712domainSeparatorAddr = address(EIP712domainSeparator);
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME)),
                keccak256(bytes(_VERSION)),
                block.chainid,
                EIP712domainSeparatorAddr
            )
        );
    }

    function testCachedDomainSeparatorV4() public {
        assertEq(
            EIP712domainSeparator.domain_separator_v4(),
            _CACHED_DOMAIN_SEPARATOR
        );
    }

    function testDomainSeparatorV4() public {
        /**
         * @dev We change the chain ID here to access the "else" branch
         * in the function `domain_separator_v4`.
         */
        vm.chainId(block.chainid + 1);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME)),
                keccak256(bytes(_VERSION)),
                block.chainid,
                EIP712domainSeparatorAddr
            )
        );
        assertEq(EIP712domainSeparator.domain_separator_v4(), digest);
    }

    function testHashTypedDataV4() public {
        address owner = makeAddr("owner");
        address spender = makeAddr("spender");
        uint256 value = 100;
        uint256 nonce = 1;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 100_000;
        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPE_HASH,
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        bytes32 digest1 = EIP712domainSeparator.hash_typed_data_v4(structHash);
        bytes32 digest2 = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP712domainSeparator.domain_separator_v4(),
                structHash
            )
        );
        assertEq(digest1, digest2);
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
        ) = EIP712domainSeparator.eip712Domain();
        assertEq(fields, hex"0f");
        assertEq(name, _NAME);
        assertEq(version, _VERSION);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, EIP712domainSeparatorAddr);
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
        assertEq(EIP712domainSeparator.domain_separator_v4(), digest);
    }

    function testFuzzDomainSeparatorV4(uint8 increment) public {
        /**
         * @dev We change the chain ID here to access the "else" branch
         * in the function `domain_separator_v4`.
         */
        vm.chainId(block.chainid + increment);
        bytes32 digest = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME)),
                keccak256(bytes(_VERSION)),
                block.chainid,
                EIP712domainSeparatorAddr
            )
        );
        assertEq(EIP712domainSeparator.domain_separator_v4(), digest);
    }

    function testFuzzHashTypedDataV4(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint64 increment
    ) public {
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + increment;
        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPE_HASH,
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        bytes32 digest1 = EIP712domainSeparator.hash_typed_data_v4(structHash);
        bytes32 digest2 = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP712domainSeparator.domain_separator_v4(),
                structHash
            )
        );
        assertEq(digest1, digest2);
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
        ) = EIP712domainSeparator.eip712Domain();
        assertTrue(fields != randomHex);
        assertEq(name, _NAME);
        assertEq(version, _VERSION);
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, EIP712domainSeparatorAddr);
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
        assertEq(EIP712domainSeparator.domain_separator_v4(), digest);
    }
}
