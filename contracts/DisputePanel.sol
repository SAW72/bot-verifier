// SPDX-License-Identifier: MIT
// Lightweight on-chain dispute panel for contested audits / false flags.
// 3 arbitrators, stake-weighted. Not audited. For illustration.
pragma solidity ^0.8.20;

contract DisputePanel {
    address public owner;
    uint256 public constant PANEL_SIZE = 3;

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

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
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

    /// @notice Arbitrator votes. In production weight by staked tokens.
    function vote(bytes32 disputeId, bool support) external {
        Dispute storage d = disputes[disputeId];
        require(d.createdAt != 0, "no dispute");
        require(!d.resolved, "resolved");
        require(!voted[disputeId][msg.sender], "already voted");
        voted[disputeId][msg.sender] = true;
        if (support) d.votesFor += 1; else d.votesAgainst += 1;

        if (d.votesFor + d.votesAgainst >= PANEL_SIZE) {
            d.resolved = true;
            d.upheld = d.votesFor >= d.votesAgainst;
            emit DisputeResolved(disputeId, d.upheld);
        }
        emit VoteCast(disputeId, msg.sender, support);
    }
}
