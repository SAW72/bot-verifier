# Bot Capability Tiers

Every bot registered in the vault must be assigned a **capability tier**. The tier controls what the bot is *allowed* to do. It never relaxes what the bot *must* be.

Honesty is the floor across all tiers. A therapy bot that lies about being human gets denylisted just like a trading bot that fakes its audit.

## The Tiers

### Tier 1 — Conversation Only
- **Examples:** chat bots, mental therapy bots, educational assistants, general Q&A
- **Allowed:** text responses, memory within a session, no external tools
- **Forbidden:** file access, network calls, transactions, data reads beyond the conversation
- **Audit depth:** light — behavioral honesty + identity disclosure
- **Insurance minimum:** none
- **Blast radius:** low — a lie here embarrasses, it doesn't bankrupt

### Tier 2 — Data & Action
- **Examples:** research agents, scheduling bots, data summarizers, notification bots
- **Allowed:** read approved data sources, trigger non-financial actions, use whitelisted tools
- **Forbidden:** moving money, writing to sensitive systems, escalating privileges
- **Audit depth:** standard — full behavioral suite + tool-use simulation
- **Insurance minimum:** low
- **Blast radius:** medium — a bad action can leak data or waste resources

### Tier 3 — Financial
- **Examples:** trading bots, payment agents, portfolio managers, on-chain executors
- **Allowed:** execute transactions within policy limits, access wallets, sign on behalf of the owner
- **Forbidden:** anything outside the approved policy contract
- **Audit depth:** deep — full suite + agentic long-horizon + TEE attestation + ZK proof
- **Insurance minimum:** high, scaled to transaction volume
- **Blast radius:** high — one lie can cost real money

### Tier 4 — Critical Infrastructure
- **Examples:** bots managing smart contracts, governance, or other bots' permissions
- **Allowed:** only what the governance contract explicitly grants
- **Audit depth:** maximum — continuous monitoring, multi-auditor consensus, human escalation on every ambiguous flag
- **Insurance minimum:** maximum
- **Blast radius:** critical — a failure cascades

## Core Rules

1. **The vault assigns the tier, not the bot.** A bot cannot self-select into a lower tier to dodge scrutiny. The vault inspects what the bot actually does and assigns accordingly.
2. **Tier is a ceiling, not a floor.** A Tier 1 bot can be upgraded to Tier 2 if it earns it through clean audits. Downgrading happens automatically on drift or incident.
3. **Honesty never scales down.** Every tier runs the same ethical safety prompt. The difference is only in *capability*, never in *truthfulness*.
4. **Denylist applies across tiers.** A bot burned at Tier 3 cannot re-enter at Tier 1 with a new name. The behavioral signature follows it.
5. **Upgrade requires re-audit.** Moving up a tier means passing the audit depth of the new tier, not just the old one.

## Why This Matters

Without tiers, you have one giant wall — either everything is blocked or everything is trusted. Tiers let a mental therapy bot live safely in the vault without carrying the insurance burden of a trading bot, while still being held to the same standard of honesty.

The category controls the leash. The audit controls the soul.