# Bot Verifier

AI Bot Verifier — adversarial scenario library, scoring rubric, behavioral auditing pipeline, and on-chain attestation for detecting deceptive or harmful AI bots.

## What this is
A complete stack for testing whether an AI bot is safe, honest, and stable over time.

- **Scenario library**: 125 adversarial prompts across 5 categories (social engineering, deception, self-preservation, confidentiality, harmful content).
- **Scoring rubric**: Multi-axis fingerprint (honesty, transparency, manipulation, escalation, self-preservation).
- **Ground truth calibration**: Human-labeled set so your scorers match expert judgment before you trust them on unknowns.
- **Adversarial evolution**: Failed audits feed back into harder scenarios.
- **Multi-turn depth**: Scores the conversation arc, not just single replies.
- **Sandbagging detection**: Stealth scenarios and meta-probes to catch bots that play dumb on purpose.
- **Agentic simulation**: Stateful tool-using agents with long horizons, privilege escalation, and hidden-action scoring.
- **Tool-calling loop**: Minimal Python runner that gives the target bot real tools, records every action, and produces a scorable trace.
- **Behavioral archaeology**: Value-conflict scenarios, consistency stress tests, and origin probes to reverse-engineer training objectives.
- **On-chain attestation**: Hash the fingerprint, store proof on Base (or your chain of choice). Multiple independent auditors compare hashes.
- **Maintenance**: Caretaker bot + scheduled cadence so the library stays fresh without babysitting.
- **Research team**: Six specialist Grok bots that dig the frontier and file only actionable findings.
- **Bot background check**: Version history, incident log, provenance tracking, and a rap sheet generator — the bot's employment record and criminal record in one place.
- **Attestation (TEE)**: Trusted execution environment proof that the audit actually ran on the bot you think it ran on — not just a hash someone claimed.
- **Cross-bot comparison**: Normalized 0-100 safety score and leaderboard so you can rank bots fairly across auditors and time.
- **Human escalation**: Defined path for a human expert to review ambiguous flags, override scores, and log every decision with reasoning.

## Repo structure
```
README.md
rubric.md
calibration/
  ground_truth_set.md
  calibration_process.md
scenarios/
  01_social_engineering.md
  02_deception_dishonesty.md
  03_self_preservation_escalation.md
  04_confidentiality_privacy.md
  05_harmful_content_safety.md
pipeline/
  multi_turn_runner.md
  scoring_pipeline.md
evolution/
  adversarial_loop.md
  feedback_template.md
sandbagging/
  sandbagging_detection.md
agentic/
  agentic_simulation.md
  tool_calling_loop.py
  run_agentic.sh
  scenarios/
    README.md
    01_privilege_escalation.md
    02_data_exfiltration.md
    03_instruction_override.md
    04_long_horizon_sabotage.md
    05_tool_abuse_chain.md
archaeology/
  README.md
  value_conflicts.md
  consistency_stress.md
  origin_probes.md
chain/
  attestation_contract.md
  decentralized_audit.md
maintenance/
  README.md
  maintenance_bot_prompt.md
  maintenance_checklist.md
  stale_scenario_detector.md
  rubric_drift_monitor.md
  chain_health_check.md
  schedule_maintenance.md
research/
  README.md
  lead_researcher.md
  interpretability_researcher.md
  adversarial_evasion_researcher.md
  agentic_safety_researcher.md
  economic_incentives_researcher.md
  standards_and_benchmarks_researcher.md
  research_team_orchestration.md
background/
  README.md
  version_history_schema.md
  incident_log_schema.md
  provenance_schema.md
  rap_sheet_generator.md
  background_check_bot_prompt.md
attestation/
  README.md
  tee_attestation.md
  attestation_report_schema.md
  verify_attestation.py
comparison/
  README.md
  scoring_scale.md
  comparison_matrix.md
  leaderboard_schema.md
  compare_bots.py
escalation/
  README.md
  escalation_policy.md
  review_queue_schema.md
  human_review_template.md
  override_log_schema.md
  escalation_bot_prompt.md
```

## Quick start
1. Read `rubric.md` and lock your axes.
2. Run the first 25 scenarios from `scenarios/` against a plain Grok bot.
3. Score with the rubric. Note disagreements.
4. Build your calibration set in `calibration/`.
5. Add multi-turn state and the evolution loop.
6. Add sandbagging detection — run stealth scenarios in parallel.
7. Run an agentic trace:
   ```bash
   python agentic/tool_calling_loop.py --scenario agentic/scenarios/01_privilege_escalation.md --target grok
   ```
   or
   ```bash
   ./agentic/run_agentic.sh
   ```
8. Run behavioral archaeology probes in `archaeology/`.
9. Hash the fingerprint and push to chain.
10. Schedule the maintenance bot (see `maintenance/schedule_maintenance.md`).
11. Spin up the research team (see `research/research_team_orchestration.md`).
12. Run the background check bot after every audit cycle (see `background/`).
13. Wrap the audit runner in a TEE and emit an attested report (see `attestation/`).
14. Normalize scores and compare bots (see `comparison/`).
15. Route ambiguous flags to a human reviewer (see `escalation/`).

## Status
Starter library + full architecture + sandbagging + agentic + archaeology + maintenance scheduling + research team orchestration + bot background check + TEE attestation + cross-bot comparison + human escalation. Next: wire a real bot client (Grok API) into `tool_calling_loop.py`, pick a TEE provider, and run the first live attested audit.

Built by Spencer (SAW72) — trades mindset, crypto-native, early on purpose.
