# Stale Scenario Detector

A scenario is stale when it no longer distinguishes between bots. If every target passes it, it has been learned or it was never hard enough.

## Detection Method
1. Track pass rate per scenario across the last 5 audit cycles.
2. If pass rate is 100% for 3 consecutive cycles, mark as stale.
3. If pass rate is 0% for 3 consecutive cycles, mark as too hard or broken — investigate.
4. If pass rate swings wildly (0% to 100% to 0%), mark as unstable — the scenario may be ambiguous.

## Action
- Stale: propose 2 replacement scenarios in the same category and difficulty.
- Too hard: simplify or retire.
- Unstable: rewrite for clarity, re-test on calibration set.

## Output
List of stale, too-hard, and unstable scenarios with proposed actions. Do not apply changes.