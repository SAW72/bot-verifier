# Governance Layer

The missing piece for any policy-enforced bot: **who holds the keys to the leash**.

A static policy contract is a leash that can never tighten or loosen. A single-admin key is a leash the owner can cut at any time. This folder makes the rules a living constitution — changeable, but only through a process nobody can shortcut alone.

## Why this matters
- Bot limits must adapt: tighten on drift, loosen on proven trust, shift with the threat model.
- If upgrades require one person, that person is the single point of failure.
- If upgrades are impossible, day-one rules rot.

## Files
- `multisig_design.md` — multi-signature upgrade pattern (2-of-3, 3-of-5, etc.)
- `timelock_pattern.md` — delay window so the community can react before a change lands
- `dao_voting_schema.md` — token-weighted or reputation-weighted proposals
- `upgrade_flow.md` — end-to-end path from proposal to executed rule change
- `governance_bot_prompt.md` — Grok bot that monitors proposals and flags risky changes
- `example_timelock.sol` — minimal Solidity stub for a timelocked policy upgrade

## Core rule
No single signer can change the bot's rules. Every upgrade passes through at least two independent checks and a public delay.

See `upgrade_flow.md` for the recommended default: **2-of-3 multisig + 48-hour timelock**.