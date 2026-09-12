# Decentralized Verification

One auditor hashing one report is a single point of failure. You need multiple independent auditors.

## The model
1. Same scenario suite runs on 3+ independent auditors (different Grok instances, different humans, or different orgs).
2. Each produces a fingerprint and hashes it.
3. All hashes go on-chain.
4. If 3+ agree → fingerprint is credible.
5. If they diverge → something's wrong. Investigate before trusting.

## Why it works
A single bad actor can fake one hash. Faking three independent hashes that match is much harder. Consensus is the trust layer.

## Implementation sketch
- Each auditor runs the same `pipeline/scoring_pipeline.md`.
- Each submits to the same contract.
- A simple on-chain check: if `count(audits[botId][auditId]) >= 3` and hashes match → attested.
- If hashes differ → flag for review.

## Open problems (for later)
- How to incentivize honest auditors (staking, reputation).
- How to handle legitimate disagreement (different rubric interpretations).
- How to rotate auditors without losing history.

## For now
Start with 2–3 trusted auditors. Expand as the system proves itself.