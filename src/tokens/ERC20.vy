# @version ^0.3.7
"""
@title Modern and Gas-Efficient ERC20 + EIP-2612 Implementation
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""

from vyper.interfaces import ERC20

implements: ERC20

# ERC20 Token Metadata
NAME: constant(String[20]) = "TBD"
SYMBOL: constant(String[5]) = "TBD"
DECIMALS: constant(uint8) = 18

# ERC20 State Variables
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

# Events
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256

owner: public(address)
isMinter: public(HashMap[address, bool])

nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')

@external
def __init__():
    self.owner = msg.sender
    self.totalSupply = 1000
    self.balanceOf[msg.sender] = 1000
    self.totalSupply = 1000
    self.balanceOf[msg.sender] = 1000

    # EIP-712
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(NAME),
            keccak256("1.0"),
            _abi_encode(chain.id, self)
        )
    )


@pure
@external
def name() -> String[20]:
    return NAME


@pure
@external
def symbol() -> String[5]:
    return SYMBOL


@pure
@external
def decimals() -> uint8:
    return DECIMALS


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(sender:address, receiver: address, amount: uint256) -> bool:
    self.allowance[sender][msg.sender] -= amount
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(sender, receiver, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    """
    @param spender The address that will execute on owner behalf.
    @param amount The amount of token to be transfered.
    """
    self.allowance[msg.sender][spender] = amount

    log Approval(msg.sender, spender, amount)
    return True


@external
def burn(amount: uint256) -> bool:
    """
    @notice Burns the supplied amount of tokens from the sender wallet.
    @param amount The amount of token to be burned.
    """
    self.balanceOf[msg.sender] -= amount
    self.totalSupply -= amount

    log Transfer(msg.sender, ZERO_ADDRESS, amount)
    return True


@external
def mint(receiver: address, amount: uint256) -> bool:
    """
    @notice Function to mint tokens
    @param receiver The address that will receive the minted tokens.
    @param amount The amount of tokens to mint.
    @return A boolean that indicates if the operation was successful.
    """
    assert msg.sender == self.owner or self.isMinter[msg.sender], "Access is denied."
    assert msg.sender == self.owner, "Access is denied."

    self.totalSupply += amount
    self.balanceOf[receiver] += amount

    log Transfer(ZERO_ADDRESS, receiver, amount)
    return True


@external
def addMinter(target: address) -> bool:
    assert msg.sender == self.owner
    assert target != ZERO_ADDRESS, "Cannot add zero address as minter."
    self.isMinter[target] = True
    return True


@external
def permit(owner: address, spender: address, amount: uint256, expiry: uint256, signature: Bytes[65]) -> bool:
    """
    @notice
        Approves spender by owner's signature to expend owner's tokens.
        See https://eips.ethereum.org/EIPS/eip-2612.
    @param owner The address which is a source of funds and has signed the Permit.
    @param spender The address which is allowed to spend the funds.
    @param amount The amount of tokens to be spent.
    @param expiry The timestamp after which the Permit is no longer valid.
    @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v.
    @return True, if transaction completes successfully
    """
    assert owner != ZERO_ADDRESS  # dev: invalid owner
    assert expiry == 0 or expiry >= block.timestamp  # dev: permit expired
    nonce: uint256 = self.nonces[owner]
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(
                _abi_encode(
                    PERMIT_TYPE_HASH,
                    owner,
                    spender,
                    amount,
                    nonce,
                    expiry,
                )
            )
        )
    )
    # NOTE: signature is packed as r, s, v
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature
    self.allowance[owner][spender] = amount
    self.nonces[owner] = nonce + 1

    log Approval(owner, spender, amount)
    return True
