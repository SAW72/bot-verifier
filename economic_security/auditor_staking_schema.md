# Auditor Staking Schema

## On-chain state
```solidity
struct Auditor {
    address auditor;
    uint256 stake;
    uint256 auditsSubmitted;
    uint256 fraudCount;
    bool active;
}

mapping(address => Auditor) public auditors;
uint256 public minStake;
uint256 public disputeWindow;
```

## Functions
- `stake()` — deposit tokens, become active auditor.
- `submitAudit(bytes32 fingerprint, string reportCid, address targetBot)` — record a run.
- `challenge(bytes32 fingerprint, string evidenceCid)` — open a dispute.
- `resolveChallenge(bytes32 fingerprint, bool fraudProven)` — slash or release.
- `withdrawStake()` — exit after cooldown, only if no open disputes.

## Events
- `Staked(address auditor, uint256 amount)`
- `AuditSubmitted(bytes32 fingerprint, address auditor, address target)`
- `ChallengeOpened(bytes32 fingerprint, address challenger)`
- `Slashed(address auditor, uint256 amount)`
- `RewardPaid(address auditor, uint256 amount)`

Keep the contract minimal. The intelligence lives off-chain; the chain only enforces the economics.