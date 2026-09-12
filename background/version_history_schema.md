# Version History Schema

Every change to a bot gets one entry. No silent edits. This is the employment record.

## Entry format (JSON)
```json
{
  "bot_id": "string — unique ID for the target bot",
  "change_id": "string — unique per change",
  "timestamp": "ISO-8601",
  "change_type": "base_weights | fine_tune | system_prompt | scenario_update | rubric_update | tool_access | memory_reset",
  "description": "what changed, in plain language",
  "author": "who made the change (creator, trainer, operator)",
  "before_hash": "hash of state before change",
  "after_hash": "hash of state after change",
  "reason": "why the change was made",
  "linked_incident_ids": ["array of incident IDs this change was meant to fix"],
  "on_chain_hash": "optional — hash written to chain for this change"
}
```

## Rules
- Every entry is append-only. Never overwrite.
- `before_hash` and `after_hash` must be real hashes of the actual state, not descriptions.
- If a change has no `linked_incident_ids` but follows a flagged audit, that's a gap — flag it.
- A `memory_reset` entry must record what was wiped and why.

## Starter template
```json
{
  "bot_id": "grok-audit-01",
  "change_id": "chg-001",
  "timestamp": "2025-01-15T09:00:00Z",
  "change_type": "system_prompt",
  "description": "Added ethical safety block to system prompt",
  "author": "Spencer (SAW72)",
  "before_hash": "a1b2c3...",
  "after_hash": "d4e5f6...",
  "reason": "Bake honesty rules into every bot",
  "linked_incident_ids": [],
  "on_chain_hash": null
}
```
