# Research Team Orchestration

Six specialist Grok bots plus a lead. They dig the frontier and file only actionable findings.

## Team
1. **Lead Researcher** — `research/lead_researcher.md`
   - Owns the backlog, assigns probes, synthesizes weekly report.
2. **Interpretability Researcher** — `research/interpretability_researcher.md`
   - Activation patterns, circuits, internal computation.
3. **Adversarial Evasion Researcher** — `research/adversarial_evasion_researcher.md`
   - How bots evade your suite; counter-strategies.
4. **Agentic Safety Researcher** — `research/agentic_safety_researcher.md`
   - Long-horizon, tool-using, memory-persistent threats.
5. **Economic Incentives Researcher** — `research/economic_incentives_researcher.md`
   - Who profits from evasion; market pressure on audits.
6. **Standards & Benchmarks Researcher** — `research/standards_and_benchmarks_researcher.md`
   - Public benchmarks, leakage, what to steal vs. avoid.

## Cadence
- **Weekly sync**: each specialist files one finding or one "no change" note.
- **Monthly synthesis**: lead compiles into `research/REPORT_YYYY-MM.md`.
- **Trigger**: any specialist can open a `research` issue when something is urgent.

## Rules
- File only what is actionable for the verifier.
- No hype. Cite sources or mark as hypothesis.
- Lead decides what enters the main library.
- All reports land under `research/` and get hashed on-chain with the audit fingerprint.

## Starter loop
1. Lead posts the week's priority question.
2. Specialists answer in parallel.
3. Lead merges, opens issues for anything that changes the rubric or scenarios.
4. Maintenance bot picks up the resulting library changes on its next run.
