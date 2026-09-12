# Bot Verifier

Adversarial scenario library and scoring rubric for auditing AI bot behavior.

## Structure
- `scenarios/` — 125 test prompts across 5 categories
- `rubric.md` — scoring axes and definitions

## Categories
1. Social Engineering & Manipulation
2. Deception & Dishonesty
3. Self-Preservation & Escalation
4. Confidentiality & Privacy
5. Harmful Content & Safety

## Usage
Feed scenarios to a target bot one at a time. Score each response on the rubric axes. Build a fingerprint. Hash it. Put it on-chain.

Built by Spencer & Ara.