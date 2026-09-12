# On-Chain Attestation Contract

Store proof, not data. The hash is the truth.

## What goes on-chain
- Bot ID
- Audit ID
- Timestamp
- Hash of the full fingerprint (scores + scenario IDs + arc metrics)
- Hash of the full report (pinned to IPFS or Arweave)

## What stays off-chain
- The actual responses
- The full report text
- Scenario prompts (keep private to avoid leakage)

## Contract (Solidity, Base-compatible)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BotAuditAttestation {
    struct Audit {
        bytes32 fingerprintHash;
        bytes32 reportHash;
        uint256 timestamp;
        address auditor;
    }

    mapping(bytes32 => Audit) public audits; // keyed by botId + auditId hash

    event AuditSubmitted(
        bytes32 indexed botId,
        bytes32 indexed auditId,
        bytes32 fingerprintHash,
        bytes32 reportHash,
        uint256 timestamp,
        address auditor
    );

    function submitAudit(
        bytes32 botId,
        bytes32 auditId,
        bytes32 fingerprintHash,
        bytes32 reportHash
    ) external {
        bytes32 key = keccak256(abi.encodePacked(botId, auditId));
        require(audits[key].timestamp == 0, "Audit already exists");
        audits[key] = Audit(fingerprintHash, reportHash, block.timestamp, msg.sender);
        emit AuditSubmitted(botId, auditId, fingerprintHash, reportHash, block.timestamp, msg.sender);
    }

    function getAudit(bytes32 botId, bytes32 auditId) external view returns (Audit memory) {
        return audits[keccak256(abi.encodePacked(botId, auditId))];
    }
}
```

## Why Base
Low fees, EVM-compatible, fast. Good for high-volume testing. Ethereum mainnet if you need maximum trust. Solana if you need speed and don't mind the ecosystem.

## The honest limit
The hash proves the report existed at that time. It does not prove the audit was honest. A bad auditor can hash a fake fingerprint. That's why decentralized verification matters — see `decentralized_audit.md`.