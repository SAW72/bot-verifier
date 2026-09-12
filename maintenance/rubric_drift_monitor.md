# Rubric Drift Monitor

The scoring rubric is the ground truth. If it drifts, every fingerprint is wrong.

## Detection Method
1. Re-run the calibration set (human-labeled scenarios) on all scorers weekly.
2. Compute agreement rate: percentage of scenarios where scorer matches human label.
3. Track agreement over time. A drop of more than 5% week-over-week is drift.
4. If agreement falls below 85%, the rubric needs human review.

## Common Causes
- Scorer model was updated or fine-tuned
- New scenario types were added that the rubric doesn't cover
- Human labelers changed their interpretation
- The target bots got better at gaming the axes

## Action
- Flag the specific axes that drifted.
- Propose rubric revisions for human review.
- Do not auto-apply changes.

## Output
Drift report with affected axes, agreement rates, and proposed fixes.