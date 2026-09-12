# Maintenance Layer

This folder keeps the verifier alive. Scenarios go stale, rubrics drift, gas runs out, and the chain needs watching. The maintenance bot handles the boring work so the system doesn't rot.

## Files
- `maintenance_bot_prompt.md` — system prompt for the caretaker bot
- `maintenance_checklist.md` — weekly and monthly tasks
- `stale_scenario_detector.md` — how to find dead prompts
- `rubric_drift_monitor.md` — how to catch scoring drift
- `chain_health_check.md` — gas, contract, and attestation checks

Run the maintenance bot on a schedule. It reports, it doesn't silently change things.