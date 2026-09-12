// SPDX-License-Identifier: MIT
// Token/stake-weighted governor. Passed proposals queue into BVTTimelock.
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

import { BVTStaking } from "./BVTStaking.sol";
import { BVTTimelock } from "./BVTTimelock.sol";

/// @title BVTGovernor
/// @notice BVT holders who have staked vote on denylist upgrades, tier/fee
/// changes, and contract parameters. Execution is always delayed by the timelock.
contract BVTGovernor {
    uint256 public constant BPS_DENOM = 10_000;

    BVTStaking public immutable staking;
    BVTTimelock public immutable timelock;

    address public admin;
    uint256 public votingPeriod = 5 days;
    uint256 public quorumBps = 1_000; // 10% of snapshot totalStaked
    uint256 public proposalThreshold; // set to staking.minStake() at deploy
    uint256 public nextProposalId;

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Queued,
        Executed,
        Cancelled
    }

    struct Proposal {
        address proposer;
        address[] targets;
        bytes[] calldatas;
        uint256 start;
        uint256 end;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 snapshotStaked;
        uint256 batchId;
        bool queued;
        bool cancelled;
        bytes32 descriptionHash;
    }

    mapping(uint256 => Proposal) internal _proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(
        uint256 indexed id, address indexed proposer, address[] targets, string description, uint256 end
    );
    event VoteCast(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event ProposalQueued(uint256 indexed id, uint256 batchId);
    event ProposalCancelled(uint256 indexed id);
    event ParamsUpdated(uint256 votingPeriod, uint256 quorumBps, uint256 proposalThreshold);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Governor: not admin");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "Governor: not timelock");
        _;
    }

    constructor(
        BVTStaking _staking,
        BVTTimelock _timelock,
        address _admin
    ) {
        require(address(_staking) != address(0) && address(_timelock) != address(0), "Governor: zero");
        require(_admin != address(0), "Governor: admin zero");
        staking = _staking;
        timelock = _timelock;
        admin = _admin;
        proposalThreshold = _staking.minStake();
    }

    function proposals(
        uint256 id
    )
        external
        view
        returns (
            address proposer,
            uint256 start,
            uint256 end,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 snapshotStaked,
            uint256 batchId,
            bool queued,
            bool cancelled
        )
    {
        Proposal storage p = _proposals[id];
        return
            (p.proposer, p.start, p.end, p.forVotes, p.againstVotes, p.snapshotStaked, p.batchId, p.queued, p.cancelled);
    }

    function propose(
        address[] calldata targets,
        bytes[] calldata calldatas,
        string calldata description
    ) external returns (uint256 id) {
        require(targets.length > 0 && targets.length == calldatas.length, "Governor: length");
        require(staking.stakeOf(msg.sender) >= proposalThreshold, "Governor: threshold");
        id = nextProposalId++;
        Proposal storage p = _proposals[id];
        p.proposer = msg.sender;
        for (uint256 i = 0; i < targets.length; i++) {
            p.targets.push(targets[i]);
            p.calldatas.push(calldatas[i]);
        }
        p.start = block.timestamp;
        p.end = block.timestamp + votingPeriod;
        p.snapshotStaked = staking.totalStaked();
        p.descriptionHash = keccak256(bytes(description));
        require(p.snapshotStaked > 0, "Governor: no stake");
        emit ProposalCreated(id, msg.sender, targets, description, p.end);
    }

    function vote(
        uint256 id,
        bool support
    ) external {
        Proposal storage p = _proposals[id];
        require(p.end != 0, "Governor: unknown");
        require(block.timestamp >= p.start && block.timestamp < p.end, "Governor: not active");
        require(!hasVoted[id][msg.sender], "Governor: voted");
        uint256 weight = staking.stakeOf(msg.sender);
        require(weight > 0, "Governor: no stake");
        hasVoted[id][msg.sender] = true;
        if (support) p.forVotes += weight;
        else p.againstVotes += weight;
        emit VoteCast(id, msg.sender, support, weight);
    }

    function queue(
        uint256 id
    ) external returns (uint256 batchId) {
        require(state(id) == ProposalState.Succeeded, "Governor: not succeeded");
        Proposal storage p = _proposals[id];
        p.queued = true;
        batchId = timelock.queue(p.targets, p.calldatas);
        p.batchId = batchId;
        emit ProposalQueued(id, batchId);
    }

    function cancel(
        uint256 id
    ) external {
        Proposal storage p = _proposals[id];
        require(p.end != 0 && !p.queued && !p.cancelled, "Governor: closed");
        require(msg.sender == p.proposer || msg.sender == admin, "Governor: cannot cancel");
        p.cancelled = true;
        emit ProposalCancelled(id);
    }

    function state(
        uint256 id
    ) public view returns (ProposalState) {
        Proposal storage p = _proposals[id];
        require(p.end != 0, "Governor: unknown");
        if (p.cancelled) return ProposalState.Cancelled;
        if (p.queued) {
            (,,, bool executed, bool cancelledBatch) = timelock.getBatch(p.batchId);
            if (cancelledBatch) return ProposalState.Cancelled;
            if (executed) return ProposalState.Executed;
            return ProposalState.Queued;
        }
        if (block.timestamp < p.end) return ProposalState.Active;
        uint256 voted = p.forVotes + p.againstVotes;
        if (p.snapshotStaked == 0 || voted * BPS_DENOM < p.snapshotStaked * quorumBps) {
            return ProposalState.Defeated;
        }
        if (p.forVotes <= p.againstVotes) return ProposalState.Defeated;
        return ProposalState.Succeeded;
    }

    function setParams(
        uint256 _votingPeriod,
        uint256 _quorumBps,
        uint256 _proposalThreshold
    ) external onlyTimelock {
        require(_votingPeriod >= 1 hours && _votingPeriod <= 30 days, "Governor: period");
        require(_quorumBps > 0 && _quorumBps <= BPS_DENOM, "Governor: quorum");
        votingPeriod = _votingPeriod;
        quorumBps = _quorumBps;
        proposalThreshold = _proposalThreshold;
        emit ParamsUpdated(_votingPeriod, _quorumBps, _proposalThreshold);
    }

    function setAdmin(
        address next
    ) external onlyAdmin {
        require(next != address(0), "Governor: admin zero");
        admin = next;
    }
}
