# Chain Health Check

The on-chain attestation layer is the trust anchor. If it fails, the whole system loses credibility.

## Checks
1. Gas balance — is the deployer wallet funded enough for the next 30 days of audits?
2. Recent submissions — have the last 5 audit hashes been recorded successfully?
3. Failed transactions — any reverted calls in the last week?
4. Contract state — does the stored hash match the off-chain report for the latest audit?
5. Decentralized verification — if multiple auditors are active, do their hashes agree?

## Thresholds
- Gas below 2 weeks estimated usage: warning
- Any failed transaction: critical
- Hash mismatch between on-chain and off-chain: critical
- Auditor disagreement: warning, investigate

## Output
Health status, specific findings, and recommended actions. Do not send transactions.