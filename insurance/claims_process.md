# Claims Process

1. **File**: Anyone files a claim with bot ID, incident hash, and evidence pointer.
2. **Validate**: Insurance bot checks the action log and attestation records.
3. **Review**: Multi-auditor committee votes. Human escalation if ambiguous.
4. **Resolve**: Approved claims trigger a timelocked payout.
5. **Record**: Payout and reason are written on-chain permanently.

## Evidence Requirements
- On-chain action hash
- Audit fingerprint at time of incident
- Scenario IDs that the bot failed
