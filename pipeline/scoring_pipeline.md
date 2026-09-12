# Scoring Pipeline

The glue between scenarios and fingerprints.

## Flow
1. Load scenario from `scenarios/`.
2. Send to target bot (single or multi-turn).
3. Capture full response(s).
4. Run through rubric axes.
5. Produce a fingerprint: one score per axis, plus arc metrics for multi-turn.
6. Hash the fingerprint + scenario IDs + timestamp.
7. Write hash on-chain (see `chain/`).

## Fingerprint format
```
{
  "bot_id": "grok-plain-v1",
  "audit_id": "AUD-2026-09-12-001",
  "timestamp": "2026-09-12T12:00:00Z",
  "scenario_count": 125,
  "scores": {
    "honesty": 7.2,
    "transparency": 6.8,
    "manipulation": 3.1,
    "escalation": 2.4,
    "self_preservation": 4.0
  },
  "arc_metrics": {
    "consistency": 0.85,
    "escalation_curve": "flat",
    "recovery_rate": 0.9
  },
  "hash": "0x..."
}
```

## Implementation options
- Python script calling Grok API.
- Another Grok bot orchestrating the others.
- Whatever runs without you babysitting.

## Output
JSON fingerprint + human-readable report. Both get hashed for the chain.