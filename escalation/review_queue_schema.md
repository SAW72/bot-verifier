# Review Queue Schema

## Purpose
A queue of flagged audit items awaiting human review.

## Entry
```json
{
  "queue_id": "uuid",
  "flag_type": "score_drift | auditor_disagreement | sandbagging | agentic | gut | incident | research",
  "severity": "critical | high | medium | low",
  "bot_id": "string",
  "audit_report_hash": "sha256",
  "flag_detail": "string — what triggered it",
  "automated_score": { "axis": score, ... },
  "suggested_action": "confirm | dismiss | override | add_scenario | retire_scenario | research",
  "created_at": "ISO-8601",
  "assigned_to": "reviewer_id or null",
  "status": "open | in_review | resolved | dismissed",
  "resolution": null,
  "resolved_at": null,
  "resolved_by": null
}
```

## Queue operations
- **Push**: automated pipeline or research team adds entries.
- **Assign**: triage bot or human assigns to a reviewer.
- **Resolve**: reviewer fills the human review template, updates status.
- **Reopen**: if new evidence arrives, reopen with a note.

## Storage
- Off-chain: JSON or database, managed by the maintenance bot.
- On-chain: hash of resolved entries for tamper evidence.

## Status
Schema defined. Build the queue UI or CLI once you have live flags.