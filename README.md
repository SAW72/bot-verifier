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

## Status
Starter library + full architecture + sandbagging + agentic + archaeology + maintenance scheduling + research team orchestration. Next: wire a real bot client (Grok API) into `tool_calling_loop.py`, enable the GitHub Actions cadence, and run the first live research cycle.

Built by Spencer (SAW72) — trades mindset, crypto-native, early on purpose.
