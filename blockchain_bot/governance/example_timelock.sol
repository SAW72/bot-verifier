// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Minimal timelocked policy upgrade stub.
 * Combines a 2-of-3 multisig gate with a 48-hour delay.
 * Real deployment should use audited libraries (OpenZeppelin TimelockController).
 */
contract PolicyTimelock {
    address[3] public signers;
    uint256 public constant DELAY = 48 hours;
    uint256 public constant MIN_SIGS = 2;

    struct Proposal {
        bytes32 policyHash;
        uint256 executeAfter;
        bool executed;
        bool cancelled;
        uint256 sigCount;
        mapping(address => bool) signed;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    event ProposalQueued(uint256 indexed id, bytes32 policyHash, uint256 executeAfter);
    event ProposalSigned(uint256 indexed id, address signer);
    event ProposalExecuted(uint256 indexed id);
    event ProposalCancelled(uint256 indexed id, string reason);

    modifier onlySigner() {
        bool isSigner = false;
        for (uint i = 0; i < signers.length; i++) {
            if (msg.sender == signers[i]) { isSigner = true; break; }
        }
        require(isSigner, "not a signer");
        _;
    }

    constructor(address[3] memory _signers) {
        signers = _signers;
    }

    function queueProposal(bytes32 policyHash) external onlySigner returns (uint256) {
        uint256 id = nextProposalId++;
        Proposal storage p = proposals[id];
        p.policyHash = policyHash;
        p.executeAfter = block.timestamp + DELAY;
        emit ProposalQueued(id, policyHash, p.executeAfter);
        return id;
    }

    function signProposal(uint256 id) external onlySigner {
        Proposal storage p = proposals[id];
        require(!p.signed[msg.sender], "already signed");
        require(!p.executed && !p.cancelled, "proposal closed");
        p.signed[msg.sender] = true;
        p.sigCount++;
        emit ProposalSigned(id, msg.sender);
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        require(p.sigCount >= MIN_SIGS, "insufficient signatures");
        require(block.timestamp >= p.executeAfter, "delay not passed");
        require(!p.executed && !p.cancelled, "already closed");
        p.executed = true;
        // In production: call the policy contract's upgrade function here.
        emit ProposalExecuted(id);
    }

    function cancel(uint256 id, string calldata reason) external onlySigner {
        Proposal storage p = proposals[id];
        require(!p.executed, "already executed");
        p.cancelled = true;
        emit ProposalCancelled(id, reason);
    }
}