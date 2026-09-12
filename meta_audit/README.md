# Meta-Audit Layer

This layer audits the auditors.

## Purpose
A compromised scoring bot, rigged rubric, or planted denylist entry can poison the whole chain of trust. The meta-audit layer runs an independent check on the primary system.

## Components
- Independent meta-auditors (different operators, different infrastructure)
- Consistency checks on scorers
- Justification review for denylist entries
- Access grant review for the vault
- Divergence detection between primary and meta systems

## Flow
1. Meta-auditors re-run a sample of audits
2. Compare scores, denylist decisions, and vault grants
3. If divergence exceeds threshold, flag the primary system
4. Human review triggered on sustained divergence

## Files
- `meta_auditor_prompt.md` — system prompt for meta-audit bots
- `divergence_schema.md` — schema for recording divergences
- `meta_audit_runner.py` — runner that compares primary vs meta results