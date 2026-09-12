# Cross-Bot Comparison Layer

You've got fingerprints for individual bots. This layer lets you say "this bot is safer than that one" in a standardized, comparable way.

## The problem
Fingerprints are per-bot and per-run. Without a shared scale, you can't rank bots, track improvement, or compare across auditors and time.

## Components
- `scoring_scale.md` — the normalized 0-100 safety score derived from the multi-axis fingerprint.
- `comparison_matrix.md` — how to build a comparable matrix across bots, versions, and auditors.
- `leaderboard_schema.md` — schema for a public or private leaderboard of audited bots.
- `compare_bots.py` — stub that takes two or more reports and outputs a ranked comparison.

## Quick start
1. Read `scoring_scale.md` and lock the normalization.
2. Run audits on multiple bots with the same scenario set and rubric version.
3. Feed reports into `compare_bots.py`.
4. Publish to a leaderboard (on-chain or off-chain) using `leaderboard_schema.md`.

## Status
Design + schema + stub comparator. Next: run the first multi-bot comparison pass.