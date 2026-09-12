# Dispute Schema

```json
{
  "dispute_id": "string",
  "type": "audit_disagreement | false_positive | insurance_claim | denylist_challenge",
  "bot_id": "string",
  "evidence_hash": "string",
  "filed_by": "address",
  "filed_at": "timestamp",
  "panel": ["arbitrator_1", "arbitrator_2", "arbitrator_3"],
  "votes": [
    {"arbitrator": "...", "decision": "approve|reject|abstain", "reasoning_hash": "..."}
  ],
  "outcome": "approved|rejected|escalated",
  "resolved_at": "timestamp"
}
```
