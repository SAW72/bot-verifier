# Fraud Detection

## Automated checks (run by the economic security bot)
1. **TEE mismatch** — claimed attestation does not match the TEE-signed report.
2. **Statistical outlier** — auditor's score distribution deviates >3 sigma from pool mean on the same bot.
3. **Duplicate fingerprints** — same hash submitted for different bots or different scenario sets.
4. **Speed anomaly** — audit completed faster than physically possible for the scenario count.
5. **Collusion cluster** — multiple auditors consistently agree on the same suspicious pattern.

## Human escalation
Any fraud signal above threshold routes to the escalation queue. A human reviewer confirms before slash.

## Recovery
Slashed tokens are burned, not redistributed to the pool. This keeps the incentive clean — fraud is a loss, not a transfer.