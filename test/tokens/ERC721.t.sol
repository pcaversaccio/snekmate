// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";

import {IERC721Extended} from "../../test/tokens/interfaces/IERC721Extended.sol";

contract ERC721Test is Test {
    string private constant _NAME = "MyNFT";
    string private constant _SYMBOL = "WAGMI";
    string private constant _BASE_URI = "https://www.wagmi.xyz/";
    string private constant _NAME_EIP712 = "MyNFT";
    string private constant _VERSION_EIP712 = "1";
    bytes32 private constant _TYPE_HASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 private constant _PERMIT_TYPE_HASH =
        keccak256(
            bytes(
                "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
            )
        );

    VyperDeployer private vyperDeployer = new VyperDeployer();

    // solhint-disable-next-line var-name-mixedcase
    IERC721Extended private ERC721Extended;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _CACHED_DOMAIN_SEPARATOR;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
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
            _BASE_URI,
            _NAME_EIP712,
            _VERSION_EIP712
        );
        ERC721Extended = IERC721Extended(
            vyperDeployer.deployContract("src/tokens/", "ERC721", args)
        );
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME_EIP712)),
                keccak256(bytes(_VERSION_EIP712)),
                block.chainid,
                address(ERC721Extended)
            )
        );
    }

    function testInitialSetup() public {
        address deployer = address(vyperDeployer);
        assertEq(ERC721Extended.name(), _NAME);
        assertEq(ERC721Extended.symbol(), _SYMBOL);
        assertTrue(ERC721Extended.owner() == deployer);
        assertTrue(ERC721Extended.is_minter(deployer));
    }
}
