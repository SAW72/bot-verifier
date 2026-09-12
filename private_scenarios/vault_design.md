# Private Scenario Vault Design

## Layers
1. **Public library** — the 125 scenarios everyone can see. Used for calibration and open research.
2. **Private vault** — encrypted scenarios, never published. Released only during a live audit.
3. **Stealth set** — scenarios generated fresh per audit, never stored, never reused.

## Release flow
1. Audit is scheduled. Target bot is identified.
2. Vault bot selects a fresh subset from the private vault + generates 5-10 stealth scenarios.
3. Scenarios are encrypted with the auditor's public key.
4. Auditor decrypts only inside the TEE during the run.
5. After the audit, the subset is retired and replaced.

## Why it works
A bot owner cannot train against what they cannot see. Even if they guess the categories, the specific prompts and the stealth set are unknown until the moment of testing.