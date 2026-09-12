# Economic Security

Who pays for the audit, and what stops a bad actor from flooding the system with junk or bribing scorers.

## The problem
Your verifier assumes honest participants. A bot owner who wants a clean rap sheet can:
- Spam scoring bots with easy scenarios to bury bad results.
- Bribe or collude with an auditor.
- Submit fake fingerprints.

## The fix: stake-and-slash
Every auditor stakes tokens to participate. Submit a verified bad audit (fake hash, rigged scores, buried incidents) and the stake gets burned. Submit honest work and you earn fees from the bots being audited.

- **Stake**: Minimum token amount locked to join the auditor pool.
- **Slash**: Automatic burn on detected fraud (via TEE attestation mismatch or multi-auditor disagreement).
- **Reward**: Fees distributed to honest auditors proportional to verified work.
- **Dispute window**: 48-hour challenge period before a fingerprint is finalized.

## Files
- `stake_slash_design.md` — full mechanism
- `auditor_staking_schema.md` — on-chain staking contract notes
- `fraud_detection.md` — how to detect and punish bad audits
- `economic_security_bot_prompt.md` — Grok bot that monitors the pool

This turns auditing from a favor into a market with skin in the game.