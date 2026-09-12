// SPDX-License-Identifier: MIT
// Lightweight on-chain dispute panel for contested audits / false flags.
// Appointed 3-arbitrator allowlist. Not audited. For illustration.
pragma solidity ^0.8.20;

contract DisputePanel {
    address public owner;
    uint256 public constant PANEL_SIZE = 3;

    mapping(address => bool) public isArbitrator;
    uint256 public arbitratorCount;

    struct Dispute {
        bytes32 subjectHash; // botId or audit hash
        address challenger;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        bool resolved;
        bool upheld; // true if original decision stands
        uint256 createdAt;
    }

    mapping(bytes32 => Dispute) public disputes; // disputeId => Dispute
    mapping(bytes32 => mapping(address => bool)) public voted;

    event DisputeOpened(bytes32 indexed disputeId, bytes32 indexed subjectHash, address challenger);
    event VoteCast(bytes32 indexed disputeId, address voter, bool support);
    event DisputeResolved(bytes32 indexed disputeId, bool upheld);
    event ArbitratorUpdated(address indexed account, bool allowed);
    event OwnerUpdated(address indexed previous, address indexed next);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "owner zero");
        emit OwnerUpdated(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Appoint or revoke an allowlisted arbitrator. Only these addresses may vote.
    function setArbitrator(address account, bool allowed) external onlyOwner {
        require(account != address(0), "zero arbitrator");
        if (isArbitrator[account] == allowed) return;
        isArbitrator[account] = allowed;
        if (allowed) arbitratorCount += 1;
        else arbitratorCount -= 1;
        emit ArbitratorUpdated(account, allowed);
    }

    function canVote(address voter) public view returns (bool) {
        return isArbitrator[voter];
    }

    function openDispute(bytes32 disputeId, bytes32 subjectHash, string calldata reason) external {
        require(disputes[disputeId].createdAt == 0, "exists");
        disputes[disputeId] = Dispute({
            subjectHash: subjectHash,
            challenger: msg.sender,
            reason: reason,
            votesFor: 0,
            votesAgainst: 0,
            resolved: false,
            upheld: false,
            createdAt: block.timestamp
        });
        emit DisputeOpened(disputeId, subjectHash, msg.sender);
    }

    /// @notice Allowlisted arbitrator only. Random / unappointed addresses revert.
    function vote(bytes32 disputeId, bool support) external {
        require(isArbitrator[msg.sender], "not authorized");
        Dispute storage d = disputes[disputeId];
        require(d.createdAt != 0, "no dispute");
        require(!d.resolved, "resolved");
        require(!voted[disputeId][msg.sender], "already voted");
        voted[disputeId][msg.sender] = true;
        if (support) d.votesFor += 1;
        else d.votesAgainst += 1;

        if (d.votesFor + d.votesAgainst >= PANEL_SIZE) {
            d.resolved = true;
            d.upheld = d.votesFor >= d.votesAgainst;
            emit DisputeResolved(disputeId, d.upheld);
        }
        emit VoteCast(disputeId, msg.sender, support);
    }
}
