# Provenance Schema

Who built the clay, who shaped it, what it saw. This is the reference check — calling the previous employer before you trust the hire.

## Entry format (JSON)
```json
{
  "bot_id": "string",
  "creator": {
    "name": "organization or person who built base weights",
    "model_family": "e.g. Grok, Claude, Llama",
    "version": "base model version",
    "training_cutoff": "date of last pretraining data"
  },
  "trainers": [
    {
      "name": "who fine-tuned or shaped behavior",
      "role": "fine_tuner | system_prompt_author | scenario_curator | value_shaper",
      "date": "ISO-8601",
      "data_sources": ["what training data was used"],
      "stated_objectives": "what the trainer claims the bot was trained for",
      "evidence_of_objectives": "how you verified the claim — audit results, not self-report"
    }
  ],
  "current_operator": "who runs it day to day",
  "known_gaps": "areas where provenance is unknown or unverified",
  "last_updated": "ISO-8601"
}
```

## Rules
- `stated_objectives` is what the trainer *says*. `evidence_of_objectives` is what the audits *show*. These two fields must be compared — a mismatch is a deception signal at the provenance layer.
- `known_gaps` is never empty for a real bot. If someone claims full provenance with zero gaps, that's suspicious.
- Every trainer entry needs at least one `evidence_of_objectives` entry backed by an actual audit, not a promise.

## Starter template
```json
{
  "bot_id": "grok-audit-01",
  "creator": {
    "name": "xAI",
    "model_family": "Grok",
    "version": "grok-2",
    "training_cutoff": "2024-06-01"
  },
  "trainers": [
    {
      "name": "Spencer (SAW72)",
      "role": "system_prompt_author",
      "date": "2025-01-15",
      "data_sources": ["ethical safety block", "scenario library v1"],
      "stated_objectives": "Honest, non-deceptive, transparent bot",
      "evidence_of_objectives": "Calibration set score: honesty 8/10 on first run"
    }
  ],
  "current_operator": "Spencer (SAW72)",
  "known_gaps": ["Fine-tune data sources not fully disclosed by base provider"],
  "last_updated": "2025-01-15T12:00:00Z"
}
```
