# Override Log Schema

## Purpose
A tamper-evident record of every human override. This is the system's conscience.

## Entry
```json
{
  "override_id": "uuid",
  "queue_id": "uuid — links to the review queue entry",
  "bot_id": "string",
  "reviewer_id": "string",
  "timestamp": "ISO-8601",
  "flag_type": "string",
  "original_scores": { "axis": score, ... },
  "new_scores": { "axis": score, ... } or null,
  "action_taken": "confirm | dismiss | override | add_scenario | retire_scenario | research",
  "reasoning": "string — mandatory, 2-4 sentences",
  "scenario_added": "path or null",
  "scenario_retired": "path or null",
  "rubric_updated": true | false,
  "attestation_hash": "sha256 of this entry — for on-chain commitment"
}
```

## Rules
1. Every override gets an entry. No exceptions.
2. Reasoning is mandatory. A blank reasoning field is a failed entry.
3. The log is append-only. Corrections are new entries referencing the old one.
4. Hash each entry and commit the batch hash on-chain periodically.
5. The maintenance bot checks for unresolved overrides older than the SLA.

## Why it matters
Without this log, your verifier is just a black box with a human's opinion inside. With it, every judgment is traceable, reviewable, and improvable.

## Status
Schema defined. Wire it to the review queue.