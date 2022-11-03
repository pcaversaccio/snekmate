# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC-721 + EIP-4494 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


# @dev We import the `ERC165` interface, which
# is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC165
implements: ERC165


# @dev We import the `ERC721` interface, which
# is a built-in interface of the Vyper compiler.
from vyper.interfaces import ERC721
implements: ERC721


# @dev We import the `IERC721Metadata` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC721Metadata as IERC721Metadata
implements: IERC721Metadata


# @dev We import the `IERC721Receiver` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC721Receiver as IERC721Receiver
implements: IERC721Receiver


# @dev We import the `IERC721Enumerable` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC721Enumerable as IERC721Enumerable
implements: IERC721Enumerable


# @dev We import the `IERC721Permit` interface, which
# is written using standard Vyper syntax.
import interfaces.IERC721Permit as IERC721Permit
implements: IERC721Permit
