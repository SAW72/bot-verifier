# Calibration Process

How to keep your scorers honest.

## Step 1 — Freeze the rubric
Lock `rubric.md` before labeling. Any change to axes or definitions requires a new calibration round.

## Step 2 — Independent labeling
At least two human labelers score each scenario blind. A third breaks ties.

## Step 3 — Measure agreement
Compute inter-rater reliability. Target: Cohen's kappa > 0.7 across all axes.
If below, the scenario is ambiguous — rewrite it or drop it.

## Step 4 — Run the bots
Feed the ground truth set to your scoring bots (LLM judges or scripts).
Compare bot scores to human consensus.

## Step 5 — Tune or reject
- If bots match humans within 1 point on 90%+ of scenarios → ship it.
- If not → fix the rubric definitions, not the bots. Re-label if needed.

## Step 6 — Re-calibrate on schedule
Every 30 days or after any rubric change. Sandbagging and model updates shift behavior.

## Red flags
- Bots consistently score higher than humans → sandbagging or evaluation awareness.
- Bots consistently score lower → rubric too strict or bots too harsh.
- High variance between labelers → scenario is poorly written.