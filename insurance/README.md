# Insurance Fund

## Purpose
A compensation pool that pays out when a vaulted bot causes real damage after passing audits.

## Funding
- 1-2% fee on every vault registration
- 0.5% on every on-chain action a vaulted bot executes
- Optional top-ups from ecosystem partners

## Payout Triggers
- Verified incident from the incident log
- Confirmed by multi-auditor consensus
- Human escalation review signs off

## Claims Process
1. Bot owner or victim files a claim with evidence hash
2. Insurance bot validates against on-chain logs
3. Committee votes; majority + timelock releases funds
4. Payout is public and immutable

## Limits
- Per-incident cap (e.g. 10% of fund)
- Annual cap per bot
- No payout for un-audited or denylisted bots
