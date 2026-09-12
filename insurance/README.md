# Insurance Fund

> **NOT INSURANCE.**  
> This directory describes an **experimental, unregulated claims backstop / compensation-pool design**. It is **not** an insurance company, policy, certificate of insurance, or regulated coverage. It does **not** promise that any loss will be paid. Institutions that want insurance must buy it from a licensed insurer. See [DISCLAIMER.md](../DISCLAIMER.md).

## Purpose
A fee-funded experimental pool that *might* pay a documented claim when a vaulted bot causes damage after passing audits — **only if** the pool is funded, the process completes, and (for any institutional reliance) a **separate written contract** says so. **Not insurance.**

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
