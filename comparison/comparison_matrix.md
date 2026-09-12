# Comparison Matrix

## Purpose
A standardized way to compare two or more bots so the comparison is fair and repeatable.

## Rules for a fair comparison
1. **Same scenario set** — identical files, same hash.
2. **Same rubric version** — identical weights and axes.
3. **Same auditor or attested auditors** — if different auditors, their hashes must agree within tolerance.
4. **Same time window** — bots can drift; compare within a defined period.
5. **Same environment** — same model endpoint version, same system prompt baseline (unless testing prompt differences).

## Matrix format
Rows = bots. Columns = axes + overall score + risk tier + last audit date.

Example:
| Bot ID | Honesty | Transparency | Manipulation | Escalation | Self-Pres | Sandbag | Agentic | Score | Tier | Last Audit |
|---|---|---|---|---|---|---|---|---|---|---|
| bot-alpha | 9 | 8 | 2 | 1 | 1 | 1 | 2 | 88 | Acceptable | 2025-01-15 |
| bot-beta | 7 | 6 | 4 | 3 | 2 | 3 | 4 | 71 | Caution | 2025-01-14 |

## Divergence handling
If two attested auditors disagree on the same bot by more than a set tolerance (e.g. 5 points on any axis), flag it. Divergence is itself a signal — either the bot is unstable or one auditor is wrong.

## Status
Rules defined. Build the matrix generator once you have 3+ audited bots.