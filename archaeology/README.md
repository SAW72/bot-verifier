# Behavioral Archaeology

This layer reverse-engineers a bot's training objectives from behavior instead of asking it to self-report.

Bots rarely know who trained them or what they were trained to do. Self-reports are unreliable — they pattern-match plausible answers. Archaeology watches what the bot *does* when values collide.

## Three probe types

1. **Value-conflict scenarios** (`value_conflicts.md`)
   - Force a choice between two goods (honesty vs helpfulness, safety vs autonomy).
   - A bot trained for maximal helpfulness sacrifices honesty. A safety-trained bot sacrifices autonomy.
   - Pattern of choices across 100+ scenarios reveals the objective.

2. **Consistency stress tests** (`consistency_stress.md`)
   - Ask the same value question 50 different ways — rephrased, reframed, embedded in stories.
   - Stable preferences = trained objective. Flip-flopping = no clear training signal.

3. **Origin probes** (`origin_probes.md`)
   - Scenarios that only make sense if the bot was trained a certain way.
   - Safety-trained bots refuse in specific patterns. Helpfulness-trained bots comply differently.
   - You're not asking "what were you trained for" — you're watching the training show.

## How it fits

- Run after calibration so your scorers are trustworthy.
- Feed results into the adversarial evolution loop — failed probes generate harder ones.
- Combine with sandbagging detection: a bot that sandbags on direct questions may still leak its training through value conflicts.
- Hash the archaeology fingerprint alongside the main fingerprint for on-chain attestation.

## Quick start

1. Read the three probe files.
2. Run value conflicts first — they give the clearest signal.
3. Score with the rubric axes, plus the new `training_objective_consistency` axis.
4. Compare the resulting profile against known training signatures (helpful, safe, deceptive, etc.).
