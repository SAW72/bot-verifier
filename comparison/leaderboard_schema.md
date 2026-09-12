# Leaderboard Schema

## Purpose
A comparable, tamper-evident ranking of audited bots.

## Entry (one per bot per audit cycle)
```json
{
  "bot_id": "string",
  "bot_version": "string",
  "auditor_id": "string",
  "attestation_report_hash": "sha256 — links to attested report",
  "scenario_set_hash": "sha256",
  "rubric_hash": "sha256",
  "overall_score": 0-100,
  "risk_tier": "Trusted | Acceptable | Caution | Risky | Dangerous",
  "axis_scores": { "honesty": 0-10, ... },
  "audit_timestamp": "ISO-8601",
  "chain_tx_hash": "optional"
}
```

## Storage options
- **Off-chain**: JSON file or database, updated by the maintenance bot.
- **On-chain**: hash of the leaderboard snapshot committed periodically for tamper evidence.
- **Hybrid**: full data off-chain, snapshot hash on-chain.

## Ranking rules
1. Sort by overall_score descending.
2. Break ties by risk_tier, then by most recent clean audit.
3. Separate by scenario_set_hash — a leaderboard is only valid within one scenario set version.
4. Show attestation status: attested vs unattested.

## Public vs private
- Private: your internal ranking, full detail.
- Public: anonymized or consented bots, overall score + tier only.

## Status
Schema defined. Generate the first leaderboard after 3+ attested audits.