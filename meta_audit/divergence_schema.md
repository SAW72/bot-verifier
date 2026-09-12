# Divergence Schema

```json
{
  "divergence_id": "string",
  "timestamp": "ISO-8601",
  "primary_auditor_id": "string",
  "meta_auditor_id": "string",
  "bot_id": "string or null",
  "scenario_id": "string or null",
  "primary_score": "number or null",
  "meta_score": "number or null",
  "primary_decision": "string",
  "meta_decision": "string",
  "divergence_type": "score_mismatch | decision_mismatch | missing_evidence | unjustified_denylist | unauthorized_grant",
  "severity": "low | medium | high | critical",
  "likely_cause": "string",
  "resolved": false,
  "resolution": null
}
```