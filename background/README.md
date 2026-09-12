# Bot Background Check

A bot's history is its background check. This folder turns scattered logs into a structured rap sheet — version lineage, incident record, and provenance — so you can see who shaped the bot, what it did, and whether it cleaned up after.

## Why it matters
A single audit is a snapshot. A background check is the arc. Two bots can score identical on today's suite and read completely differently once you see the history: one with a clean slate and steady improvement, another with three deception flags and a quiet fine-tune in between.

## What lives here
- `version_history_schema.md` — chain-of-custody log for every change to the bot (weights, fine-tunes, system prompts, scenario updates).
- `incident_log_schema.md` — structured record of every audit failure, lie, drift, or evasion attempt.
- `provenance_schema.md` — who created, who trained, what data, what values — the reference check.
- `rap_sheet_generator.md` — pulls the three logs into one summary report with risk flags.
- `background_check_bot_prompt.md` — Grok bot that maintains the logs and generates the rap sheet on demand.

## How it connects
- Maintenance bot feeds incidents and version changes here automatically.
- On-chain attestation can hash the rap sheet summary so the history itself is tamper-evident.
- Research team uses the rap sheet to prioritize which bots need deeper archaeology.

Run the background check bot after every audit cycle. A clean rap sheet is the strongest signal you have — stronger than any single score.
