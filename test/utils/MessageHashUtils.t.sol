// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {IMessageHashUtils} from "./interfaces/IMessageHashUtils.sol";

contract MessageHashUtilsTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    IMessageHashUtils private messageHashUtils;

    address private messageHashUtilsAddr;

    function setUp() public {
        messageHashUtils = IMessageHashUtils(
            vyperDeployer.deployContract(
                "src/snekmate/utils/mocks/",
                "MessageHashUtilsMocks"
            )
        );
        messageHashUtilsAddr = address(messageHashUtils);
    }

    function testEthSignedMessageHash() public view {
        bytes32 hash = keccak256("WAGMI");
        bytes32 digest1 = messageHashUtils.to_eth_signed_message_hash(hash);
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        assertEq(digest1, digest2);
    }

    function testToDataWithIntendedValidatorHashSelf() public view {
        bytes memory data = new bytes(42);
        bytes32 digest1 = messageHashUtils
            .to_data_with_intended_validator_hash_self(data);
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19\x00", messageHashUtilsAddr, data)
        );
        assertEq(digest1, digest2);
    }

    function testToDataWithIntendedValidatorHash() public {
        address validator = makeAddr("intendedValidator");
        bytes memory data = new bytes(42);
        bytes32 digest1 = messageHashUtils.to_data_with_intended_validator_hash(
            validator,
            data
        );
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19\x00", validator, data)
        );
        assertEq(digest1, digest2);
    }

    function testToTypedDataHash() public view {
        bytes32 domainSeparator = keccak256("WAGMI");
        bytes32 structHash = keccak256("GM");
        bytes32 digest1 = messageHashUtils.to_typed_data_hash(
            domainSeparator,
            structHash
        );
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        assertEq(digest1, digest2);
    }

    function testFuzzEthSignedMessageHash(string calldata message) public view {
        bytes32 hash = keccak256(abi.encode(message));
        bytes32 digest1 = messageHashUtils.to_eth_signed_message_hash(hash);
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        assertEq(digest1, digest2);
    }

    function testFuzzToDataWithIntendedValidatorHashSelf(
        bytes calldata data
    ) public view {
        bytes32 digest1 = messageHashUtils
            .to_data_with_intended_validator_hash_self(data);
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19\x00", messageHashUtilsAddr, data)
        );
        assertEq(digest1, digest2);
    }

    function testFuzzToDataWithIntendedValidatorHash(
        address validator,
        bytes calldata data
    ) public view {
        bytes32 digest1 = messageHashUtils.to_data_with_intended_validator_hash(
            validator,
            data
        );
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19\x00", validator, data)
        );
        assertEq(digest1, digest2);
    }

    function testFuzzToTypedDataHash(
        string calldata domainSeparatorPlain,
        string calldata structPlain
    ) public view {
        bytes32 domainSeparator = keccak256(abi.encode(domainSeparatorPlain));
        bytes32 structHash = keccak256(abi.encode(structPlain));
        bytes32 digest1 = messageHashUtils.to_typed_data_hash(
            domainSeparator,
            structHash
        );
        bytes32 digest2 = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        assertEq(digest1, digest2);
    }
}
