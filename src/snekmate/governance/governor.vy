# pragma version ~=0.4.3

"""
@title Multi-Role-Based Token-Weighted Governor Reference Implementation
@custom:contract-name governor
@notice A Compound Bravo-compatible governor that uses snekmate's
        timelock_controller for proposal execution. Voting power is
        sourced from a Comp-compatible token via `getPriorVotes`.
        The implementation is inspired by Compound's implementation:
        https://docs.compound.finance/v2/governance/
"""


from .interfaces import ITimelock


# @dev We define the `IComp` interface for the Comp-compatible voting
# token. Uses `getPriorVotes` (block-based snapshot) rather than
# `getPastVotes` to prevent flash-loan attacks. The queried block
# must always be finalised (i.e. strictly less than `block.number`).
# If not `IComp` direct port with`ERC20VotesComp`compatible token -- implmenting `getPastVotes` without any other changes
interface IComp:
    def getPriorVotes(account: address, blockNumber: uint256) -> uint96: view


# @dev The maximum number of actions (calls) in a single proposal.
MAX_ACTIONS: constant(uint256) = 10

# @dev The maximum byte length of ABI-encoded calldata per action.
MAX_CALLDATA_LEN: constant(uint256) = 1_024

# @dev The maximum byte length of the proposal description string.
MAX_DESC_LEN: constant(uint256) = 1_024

# @dev Minimum and maximum voting period in blocks (~24 hours and ~2 weeks).
MIN_VOTING_PERIOD: constant(uint256) = 5_760
MAX_VOTING_PERIOD: constant(uint256) = 80_640

# @dev Minimum and maximum voting delay in blocks.
MIN_VOTING_DELAY: constant(uint256) = 1
MAX_VOTING_DELAY: constant(uint256) = 40_320

# @dev Minimum and maximum proposal threshold in token units (18 decimals).
MIN_PROPOSAL_THRESHOLD: constant(uint256) = 1_000   * 10 ** 18
MAX_PROPOSAL_THRESHOLD: constant(uint256) = 100_000 * 10 ** 18

# @dev EIP-712 typehash for the contract's domain separator.
DOMAIN_TYPEHASH: constant(bytes32) = keccak256(
    b"EIP712Domain(string name,uint256 chainId,address verifyingContract)"
)

# @dev EIP-712 typehash for the ballot struct used by `cast_vote_by_sig`.
BALLOT_TYPEHASH: constant(bytes32) = keccak256(
    b"Ballot(uint256 proposalId,uint8 support)"
)


# @dev The possible states of a proposal.
flag ProposalState:
    PENDING
    ACTIVE
    CANCELED
    DEFEATED
    SUCCEEDED
    QUEUED
    EXECUTED
# @dev Note: there is no EXPIRED state — snekmate's timelock has no
# grace period. A QUEUED proposal remains QUEUED until executed or cancelled.


struct Proposal:
    id:            uint256
    op_hash:       bytes32
    salt:          bytes32
    targets:       DynArray[address, MAX_ACTIONS]
    amounts:       DynArray[uint256, MAX_ACTIONS]
    calldatas:     DynArray[Bytes[MAX_CALLDATA_LEN], MAX_ACTIONS]
    start_block:   uint256
    end_block:     uint256
    proposer:      address
    for_votes:     uint96
    against_votes: uint96
    abstain_votes: uint96
    canceled:      bool
    executed:      bool


struct Receipt:
    has_voted: bool
    support:   uint8
    votes:     uint96


event ProposalCreated:
    id:          uint256
    proposer:    address
    targets:     DynArray[address, MAX_ACTIONS]
    amounts:     DynArray[uint256, MAX_ACTIONS]
    calldatas:   DynArray[Bytes[MAX_CALLDATA_LEN], MAX_ACTIONS]
    start_block: uint256
    end_block:   uint256
    description: String[MAX_DESC_LEN]

event ProposalQueued:
    id:      uint256
    op_hash: bytes32

event ProposalExecuted:
    id: uint256

event ProposalCanceled:
    id: uint256

event VoteCast:
    voter:   indexed(address)
    id:      uint256
    support: uint8
    votes:   uint96
    reason:  String[256]

event VotingDelaySet:
    old_voting_delay: uint256
    new_voting_delay: uint256

event VotingPeriodSet:
    old_voting_period: uint256
    new_voting_period: uint256

event ProposalThresholdSet:
    old_proposal_threshold: uint256
    new_proposal_threshold: uint256

event NewAdmin:
    old_admin: address
    new_admin: address

event NewPendingAdmin:
    old_pending_admin: address
    new_pending_admin: address

event WhitelistGuardianSet:
    old_guardian: address
    new_guardian: address

event WhitelistAccountExpirationSet:
    account:    address
    expiration: uint256


# @dev The human-readable name of this governor, used in the EIP-712 domain.
name: public(String[64])

# @dev The address of the snekmate timelock_controller that executes proposals.
timelock: public(address)

# @dev The address of the Comp-compatible voting token.
comp: public(address)

# @dev The number of blocks between proposal creation and vote start.
voting_delay: public(uint256)

# @dev The number of blocks a vote remains open.
voting_period: public(uint256)

# @dev The minimum token balance (in wei) required to create a proposal.
proposal_threshold: public(uint256)

# @dev The minimum number of for-votes required for a proposal to succeed.
quorum_votes: public(uint96)

# @dev The total number of proposals ever created; used as the proposal id.
proposal_count: public(uint256)

# @dev Storage of all proposals by id.
proposals: public(HashMap[uint256, Proposal])

# @dev Maps a proposer address to their most recently created proposal id.
latest_proposal_ids: public(HashMap[address, uint256])

# @dev Maps proposal id => voter address => receipt.
receipts: HashMap[uint256, HashMap[address, Receipt]]

# @dev The current admin of this governor.
admin: public(address)

# @dev The pending admin, set via `set_pending_admin` and confirmed via `accept_admin`.
pending_admin: public(address)

# @dev The guardian that may cancel proposals from whitelisted proposers.
whitelist_guardian: public(address)

# @dev Maps an address to a timestamp before which it is considered whitelisted.
_whitelist_account_expirations: HashMap[address, uint256]


@deploy
@payable
def __init__(
    timelock_:           address,
    comp_:               address,
    admin_:              address,
    voting_period_:      uint256,
    voting_delay_:       uint256,
    proposal_threshold_: uint256,
    quorum_votes_:       uint96,
    whitelist_guardian_: address,
):
    """
    @dev Sets all governance parameters and wires the governor to its
         timelock and voting token. The constructor is `payable` to omit
         the `msg.value` check from the creation-time EVM bytecode.

         Deployment and wiring order:
           1. Deploy snekmate `timelock_controller(min_delay, [], [], admin)`.
           2. Deploy this governor.
           3. `timelock.grantRole(PROPOSER_ROLE,  governor)`
           4. `timelock.grantRole(EXECUTOR_ROLE,  governor)`
           5. `timelock.grantRole(CANCELLER_ROLE, governor)`
           6. Deployer renounces `DEFAULT_ADMIN_ROLE` on the timelock.
           7. `governor.set_pending_admin(timelock_address)`
           8. Queue and execute `governor.accept_admin()` via the timelock.
         After step 8 the timelock controls governor parameters and the
         governor controls timelock operations.
    @param timelock_           The 20-byte address of the snekmate timelock.
    @param comp_               The 20-byte address of the Comp-compatible token.
    @param admin_              The 20-byte initial admin address.
    @param voting_period_      The initial voting period in blocks.
    @param voting_delay_       The initial voting delay in blocks.
    @param proposal_threshold_ The initial proposal threshold in token units.
    @param quorum_votes_       The initial quorum in token units.
    @param whitelist_guardian_ The 20-byte initial whitelist guardian address.
    """
    assert timelock_           != empty(address),         "Governor: zero timelock"
    assert comp_               != empty(address),         "Governor: zero comp"
    assert voting_period_      >= MIN_VOTING_PERIOD,      "Governor: voting period below min"
    assert voting_period_      <= MAX_VOTING_PERIOD,      "Governor: voting period above max"
    assert voting_delay_       >= MIN_VOTING_DELAY,       "Governor: voting delay below min"
    assert voting_delay_       <= MAX_VOTING_DELAY,       "Governor: voting delay above max"
    assert proposal_threshold_ >= MIN_PROPOSAL_THRESHOLD, "Governor: threshold below min"
    assert proposal_threshold_ <= MAX_PROPOSAL_THRESHOLD, "Governor: threshold above max"

    self.name               = "governor_snekmate"
    self.timelock           = timelock_
    self.comp               = comp_
    self.voting_period      = voting_period_
    self.voting_delay       = voting_delay_
    self.proposal_threshold = proposal_threshold_
    self.quorum_votes       = quorum_votes_
    self.admin              = admin_
    self.whitelist_guardian = whitelist_guardian_

    log VotingDelaySet(old_voting_delay=empty(uint256), new_voting_delay=voting_delay_)
    log VotingPeriodSet(old_voting_period=empty(uint256), new_voting_period=voting_period_)
    log ProposalThresholdSet(old_proposal_threshold=empty(uint256), new_proposal_threshold=proposal_threshold_)
    log NewAdmin(old_admin=empty(address), new_admin=admin_)


@external
@view
def get_receipt(proposal_id: uint256, voter: address) -> Receipt:
    """
    @notice Returns the vote receipt for `voter` on `proposal_id`.
    @param proposal_id The 32-byte proposal identifier.
    @param voter       The 20-byte voter address.
    @return Receipt    The receipt struct for this voter.
    """
    return self.receipts[proposal_id][voter]


@external
@view
def get_actions(proposal_id: uint256) -> (
    DynArray[address, MAX_ACTIONS],
    DynArray[uint256, MAX_ACTIONS],
    DynArray[Bytes[MAX_CALLDATA_LEN], MAX_ACTIONS],
):
    """
    @notice Returns the actions (targets, amounts, calldatas) of a proposal.
    @param proposal_id The 32-byte proposal identifier.
    @return            Tuple of targets, amounts, and calldatas arrays.
    """
    p: Proposal = self.proposals[proposal_id]
    return p.targets, p.amounts, p.calldatas


@external
@view
def get_proposal_state(proposal_id: uint256) -> ProposalState:
    """
    @notice Returns the current state of a proposal.
    @param proposal_id The 32-byte proposal identifier.
    @return ProposalState The current state.
    """
    return self._get_proposal_state(proposal_id)


@external
@view
def is_whitelisted(account: address) -> bool:
    """
    @notice Returns whether `account` is currently whitelisted.
    @param account The 20-byte address to check.
    @return bool   True if whitelisted, false otherwise.
    """
    return self._is_whitelisted(account)


@external
def propose(
    targets:     DynArray[address, MAX_ACTIONS],
    amounts:     DynArray[uint256, MAX_ACTIONS],
    calldatas:   DynArray[Bytes[MAX_CALLDATA_LEN], MAX_ACTIONS],
    description: String[MAX_DESC_LEN],
) -> uint256:
    """
    @notice Creates a new proposal.
    @dev    The caller must hold at least `proposal_threshold` voting power
            at the previous block. A proposer may not have another PENDING
            or ACTIVE proposal. SUCCEEDED or QUEUED proposals do not block
            a new proposal — this matches Compound Bravo exactly.
    @param targets     The 20-byte array of target contract addresses.
    @param amounts     The 32-byte array of native token amounts per action.
    @param calldatas   The ABI-encoded calldata array per action.
    @param description The human-readable proposal description.
    @return uint256    The newly created proposal id.
    """
    prior_votes: uint256 = convert(
        staticcall IComp(self.comp).getPriorVotes(msg.sender, block.number - 1),
        uint256
    )
    assert prior_votes >= self.proposal_threshold, "Governor: proposer below threshold"
    assert len(targets) != 0 and len(targets) <= MAX_ACTIONS, "Governor: invalid action count"
    assert len(targets) == len(amounts),   "Governor: targets/amounts mismatch"
    assert len(targets) == len(calldatas), "Governor: targets/calldatas mismatch"

    latest_id: uint256 = self.latest_proposal_ids[msg.sender]
    if latest_id != 0:
        assert not self._is_proposal_pending(latest_id), "Governor: proposer has pending proposal"
        assert not self._is_proposal_active(latest_id),  "Governor: proposer has active proposal"

    start_block: uint256 = block.number + self.voting_delay
    end_block:   uint256 = start_block + self.voting_period

    self.proposal_count += 1
    proposal_id: uint256 = self.proposal_count

    # @dev Deterministic unique salt per proposal derived from the proposal id.
    # The same salt is passed to both `queue` and `execute` so that the
    # snekmate operation hash is consistent across both calls.
    salt: bytes32 = keccak256(convert(proposal_id, bytes32))

    self.proposals[proposal_id] = Proposal(
        id            = proposal_id,
        op_hash       = empty(bytes32),
        salt          = salt,
        targets       = targets,
        amounts       = amounts,
        calldatas     = calldatas,
        start_block   = start_block,
        end_block     = end_block,
        proposer      = msg.sender,
        for_votes     = 0,
        against_votes = 0,
        abstain_votes = 0,
        canceled      = False,
        executed      = False,
    )

    self.latest_proposal_ids[msg.sender] = proposal_id
    log ProposalCreated(
        id=proposal_id,
        proposer=msg.sender,
        targets=targets,
        amounts=amounts,
        calldatas=calldatas,
        start_block=start_block,
        end_block=end_block,
        description=description,
    )
    return proposal_id


@external
def queue(proposal_id: uint256):
    """
    @notice Queues a succeeded proposal into the snekmate timelock.
    @dev    Single-action proposals use `schedule` for gas efficiency.
            Multi-action proposals use `schedule_batch` for atomic execution.
            The operation hash is stored in `op_hash` for use by `cancel`.
            `predecessor` is always `empty(bytes32)` — no inter-proposal
            dependency is enforced.
    @param proposal_id The 32-byte proposal identifier.
    """
    assert self._is_proposal_succeeded(proposal_id), "Governor: proposal not succeeded"

    proposal:    Proposal = self.proposals[proposal_id]
    predecessor: bytes32  = empty(bytes32)
    delay:       uint256  = staticcall ITimelock(self.timelock).get_minimum_delay()
    op_hash:     bytes32  = empty(bytes32)

    if len(proposal.targets) == 1:
        extcall ITimelock(self.timelock).schedule(
            proposal.targets[0],
            proposal.amounts[0],
            proposal.calldatas[0],
            predecessor,
            proposal.salt,
            delay,
        )
        op_hash = staticcall ITimelock(self.timelock).hash_operation(
            proposal.targets[0],
            proposal.amounts[0],
            proposal.calldatas[0],
            predecessor,
            proposal.salt,
        )
    else:
        extcall ITimelock(self.timelock).schedule_batch(
            proposal.targets,
            proposal.amounts,
            proposal.calldatas,
            predecessor,
            proposal.salt,
            delay,
        )
        op_hash = staticcall ITimelock(self.timelock).hash_operation_batch(
            proposal.targets,
            proposal.amounts,
            proposal.calldatas,
            predecessor,
            proposal.salt,
        )

    self.proposals[proposal_id].op_hash = op_hash
    log ProposalQueued(id=proposal_id, op_hash=op_hash)


@external
@payable
def execute(proposal_id: uint256):
    """
    @notice Executes a queued proposal whose timelock delay has elapsed.
    @dev    The snekmate timelock validates the READY state internally and
            reverts if the delay has not elapsed. `executed` is set to `True`
            before the external call (checks-effects-interactions pattern).
    @param proposal_id The 32-byte proposal identifier.
    """
    assert self._is_proposal_queued(proposal_id), "Governor: proposal not queued"

    proposal:    Proposal = self.proposals[proposal_id]
    predecessor: bytes32  = empty(bytes32)

    self.proposals[proposal_id].executed = True

    if len(proposal.targets) == 1:
        extcall ITimelock(self.timelock).execute(
            proposal.targets[0],
            proposal.amounts[0],
            proposal.calldatas[0],
            predecessor,
            proposal.salt,
        )
    else:
        extcall ITimelock(self.timelock).execute_batch(
            proposal.targets,
            proposal.amounts,
            proposal.calldatas,
            predecessor,
            proposal.salt,
        )

    log ProposalExecuted(id=proposal_id)


@external
def cancel(proposal_id: uint256):
    """
    @notice Cancels a proposal per Compound Bravo semantics.
    @dev    Matches the Compound Bravo implementation:
            https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorBravoDelegate.sol#L523

            Authorization matrix:
              - Proposer: can always cancel their own proposal (except EXECUTED).
              - Non-whitelisted proposer: anyone can cancel if the proposer's
                votes at `block.number - 1` are below `proposal_threshold`.
              - Whitelisted proposer: only `whitelist_guardian` can cancel,
                and only if the proposer's votes are below `proposal_threshold`.
    @param proposal_id The 32-byte proposal identifier.
    """
    assert not self._is_proposal_executed(proposal_id), "Governor: cannot cancel executed proposal"

    proposal: Proposal = self.proposals[proposal_id]

    if msg.sender != proposal.proposer:
        proposer_votes: uint256 = convert(
            staticcall IComp(self.comp).getPriorVotes(proposal.proposer, block.number - 1),
            uint256,
        )
        if self._is_whitelisted(proposal.proposer):
            assert msg.sender == self.whitelist_guardian, "Governor: only whitelist_guardian"
            assert proposer_votes < self.proposal_threshold, "Governor: whitelisted above threshold"
        else:
            assert proposer_votes < self.proposal_threshold, "Governor: proposer above threshold"

    self.proposals[proposal_id].canceled = True

    # @dev snekmate cancels by operation hash
    if proposal.op_hash != empty(bytes32):
        extcall ITimelock(self.timelock).cancel(proposal.op_hash)

    log ProposalCanceled(id=proposal_id)


@external
def cast_vote(proposal_id: uint256, support: uint8):
    """
    @notice Casts a vote on a proposal.
    @param proposal_id The 32-byte proposal identifier.
    @param support     0 = against, 1 = for, 2 = abstain.
    """
    self._cast_vote(msg.sender, proposal_id, support, "")


@external
def cast_vote_with_reason(proposal_id: uint256, support: uint8, reason: String[256]):
    """
    @notice Casts a vote on a proposal with an optional reason string.
    @param proposal_id The 32-byte proposal identifier.
    @param support     0 = against, 1 = for, 2 = abstain.
    @param reason      A human-readable reason string.
    """
    self._cast_vote(msg.sender, proposal_id, support, reason)


@external
def cast_vote_by_sig(proposal_id: uint256, support: uint8, v: uint8, r: bytes32, s: bytes32):
    """
    @notice Casts a vote on a proposal using an EIP-712 signature.
    @param proposal_id The 32-byte proposal identifier.
    @param support     0 = against, 1 = for, 2 = abstain.
    @param v           The recovery byte of the signature.
    @param r           The first 32 bytes of the signature.
    @param s           The second 32 bytes of the signature.
    """
    domain_separator: bytes32 = keccak256(
        abi_encode(DOMAIN_TYPEHASH, keccak256(self.name), self._get_chain_id(), self)
    )
    struct_hash: bytes32 = keccak256(abi_encode(BALLOT_TYPEHASH, proposal_id, support))
    digest: bytes32 = keccak256(concat(b"\x19\x01", domain_separator, struct_hash))
    signatory: address = ecrecover(digest, v, r, s)
    assert signatory != empty(address), "Governor: invalid signature"
    self._cast_vote(signatory, proposal_id, support, "")


@external
def set_voting_delay(new_voting_delay: uint256):
    """
    @notice Sets the voting delay (in blocks) between proposal creation
            and vote start.
    @param new_voting_delay The new voting delay in blocks.
    """
    assert msg.sender == self.admin,             "Governor: admin only"
    assert new_voting_delay >= MIN_VOTING_DELAY, "Governor: below min"
    assert new_voting_delay <= MAX_VOTING_DELAY, "Governor: above max"
    old: uint256 = self.voting_delay
    self.voting_delay = new_voting_delay
    log VotingDelaySet(old_voting_delay=old, new_voting_delay=new_voting_delay)


@external
def set_voting_period(new_voting_period: uint256):
    """
    @notice Sets the voting period (in blocks) during which votes are accepted.
    @param new_voting_period The new voting period in blocks.
    """
    assert msg.sender == self.admin,               "Governor: admin only"
    assert new_voting_period >= MIN_VOTING_PERIOD, "Governor: below min"
    assert new_voting_period <= MAX_VOTING_PERIOD, "Governor: above max"
    old: uint256 = self.voting_period
    self.voting_period = new_voting_period
    log VotingPeriodSet(old_voting_period=old, new_voting_period=new_voting_period)


@external
def set_proposal_threshold(new_proposal_threshold: uint256):
    """
    @notice Sets the minimum voting power required to create a proposal.
    @param new_proposal_threshold The new threshold in token units.
    """
    assert msg.sender == self.admin,                         "Governor: admin only"
    assert new_proposal_threshold >= MIN_PROPOSAL_THRESHOLD, "Governor: below min"
    assert new_proposal_threshold <= MAX_PROPOSAL_THRESHOLD, "Governor: above max"
    old: uint256 = self.proposal_threshold
    self.proposal_threshold = new_proposal_threshold
    log ProposalThresholdSet(old_proposal_threshold=old, new_proposal_threshold=new_proposal_threshold)


@external
def set_pending_admin(new_pending_admin: address):
    """
    @notice Begins a two-step admin transfer by setting `pending_admin`.
    @param new_pending_admin The 20-byte address of the proposed new admin.
    """
    assert msg.sender == self.admin, "Governor: admin only"
    old: address = self.pending_admin
    self.pending_admin = new_pending_admin
    log NewPendingAdmin(old_pending_admin=old, new_pending_admin=new_pending_admin)


@external
def accept_admin():
    """
    @notice Completes the two-step admin transfer. Must be called by
            `pending_admin`.
    """
    assert msg.sender == self.pending_admin, "Governor: not pending admin"
    old_admin: address = self.admin
    self.admin         = self.pending_admin
    self.pending_admin = empty(address)
    log NewAdmin(old_admin=old_admin, new_admin=self.admin)


@external
def set_whitelist_account_expiration(account: address, expiration: uint256):
    """
    @notice Sets the whitelist expiration timestamp for `account`.
            The account is considered whitelisted while
            `block.timestamp < expiration`.
    @param account    The 20-byte address to whitelist.
    @param expiration The Unix timestamp at which the whitelist expires.
    """
    assert msg.sender == self.admin or msg.sender == self.whitelist_guardian, \
        "Governor: admin or whitelist guardian only"
    self._whitelist_account_expirations[account] = expiration
    log WhitelistAccountExpirationSet(account=account, expiration=expiration)


@external
def set_whitelist_guardian(account: address):
    """
    @notice Sets the whitelist guardian address.
    @param account The 20-byte address of the new whitelist guardian.
    """
    assert msg.sender == self.admin, "Governor: admin only"
    old: address = self.whitelist_guardian
    self.whitelist_guardian = account
    log WhitelistGuardianSet(old_guardian=old, new_guardian=account)


@internal
def _cast_vote(voter: address, proposal_id: uint256, support: uint8, reason: String[256]):
    """
    @dev Core vote logic shared by all `cast_vote*` entry points.
         Voting power is snapshotted at `block.number - 1` to prevent
         flash-loan manipulation.
    """
    assert self._is_proposal_active(proposal_id), "Governor: voting closed"
    assert support <= 2, "Governor: invalid vote type"

    receipt: Receipt = self.receipts[proposal_id][voter]
    assert not receipt.has_voted, "Governor: already voted"

    votes: uint96 = staticcall IComp(self.comp).getPriorVotes(voter, block.number - 1)

    if support == 0:
        self.proposals[proposal_id].against_votes += votes
    elif support == 1:
        self.proposals[proposal_id].for_votes += votes
    else:
        self.proposals[proposal_id].abstain_votes += votes

    self.receipts[proposal_id][voter] = Receipt(
        has_voted = True,
        support   = support,
        votes     = votes,
    )

    log VoteCast(voter=voter, id=proposal_id, support=support, votes=votes, reason=reason)


@internal
@view
def _get_proposal_state(proposal_id: uint256) -> ProposalState:
    """
    @dev Derives the current state of a proposal from on-chain data.
         Reverts for proposal ids of zero or beyond `proposal_count`.
    """
    assert proposal_id != 0 and proposal_id <= self.proposal_count, "Governor: invalid id"

    proposal: Proposal = self.proposals[proposal_id]

    if proposal.canceled:
        return ProposalState.CANCELED

    if proposal.executed:
        return ProposalState.EXECUTED

    if block.number < proposal.start_block:
        return ProposalState.PENDING

    if block.number <= proposal.end_block:
        return ProposalState.ACTIVE

    if (
        proposal.for_votes <= proposal.against_votes or
        proposal.for_votes < self.quorum_votes
    ):
        return ProposalState.DEFEATED

    if proposal.op_hash == empty(bytes32):
        return ProposalState.SUCCEEDED

    return ProposalState.QUEUED


@internal
@view
def _is_proposal_pending(proposal_id: uint256) -> bool:
    return self._get_proposal_state(proposal_id) == ProposalState.PENDING


@internal
@view
def _is_proposal_active(proposal_id: uint256) -> bool:
    return self._get_proposal_state(proposal_id) == ProposalState.ACTIVE


@internal
@view
def _is_proposal_succeeded(proposal_id: uint256) -> bool:
    return self._get_proposal_state(proposal_id) == ProposalState.SUCCEEDED


@internal
@view
def _is_proposal_queued(proposal_id: uint256) -> bool:
    return self._get_proposal_state(proposal_id) == ProposalState.QUEUED


@internal
@view
def _is_proposal_executed(proposal_id: uint256) -> bool:
    return self._get_proposal_state(proposal_id) == ProposalState.EXECUTED


@internal
@view
def _get_chain_id() -> uint256:
    return chain.id


@internal
@view
def _is_whitelisted(account: address) -> bool:
    return self._whitelist_account_expirations[account] > block.timestamp