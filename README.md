# Bot Verifier

A system for auditing AI bots — detecting deception, drift, and danger — with on-chain attestation, decentralized consensus, and irreversible accountability.

## Architecture

The system is built in layers:

1. **Scenarios** — adversarial test library (social engineering, deception, self-preservation, confidentiality, harmful content)
2. **Calibration** — ground truth set for tuning scorers to human judgment
3. **Archaeology** — behavioral probes that reverse-engineer training objectives from behavior
4. **Sandbagging** — stealth scenarios that catch bots playing dumb during tests
5. **Agentic** — multi-turn, tool-using simulations for long-horizon behavior
6. **Pipeline** — end-to-end runner that takes a bot, runs scenarios, scores, hashes, attests
7. **Attestation** — TEE-backed signed reports proving the audit actually ran
8. **Comparison** — normalized 0-100 safety scale for fair cross-bot ranking
9. **Escalation** — human-in-the-loop review for ambiguous flags
10. **Economic Security** — stake-and-slash for auditors, private scenario vault
11. **Cross-Chain** — hub-and-spoke architecture, portable fingerprints, cached allowlist for trading bots
12. **Blockchain Bot** — brain/hands split, policy-enforced execution
13. **Governance** — multisig, timelock, DAO voting for safe rule changes
14. **Vault** — trusted-bot registry, access grants, irreversible burn
15. **Denylist** — permanent blacklist of dangerous bot fingerprints with graduated matching
16. **ZK Transparency** — zero-knowledge proofs that audits ran without revealing private scenarios
17. **Tiers** — capability tiers (chat, data, financial, critical) with honesty as the universal floor
18. **Insurance** — payout fund for bot-caused damage, funded by vault fees
19. **Dispute** — staked arbitrator panel for contested audits and false flags
20. **Consensus** — multi-auditor committee with stake-weighted voting
21. **Automation** — auto-retire stale scenarios, rubric drift flagging, gas scheduling, human veto
22. **Meta-Audit** — independent layer that audits the auditors
23. **Formal Verification** — mathematical proof of contract invariants
24. **Key Management** — HSM, distributed key ceremony, rotation, emergency freeze

## Quick Start

```bash
# Run a full audit (stub bot, no API key needed)
./pipeline/run_audit.sh

# Run meta-audit comparison
python meta_audit/meta_audit_runner.py

# Run formal verification
# See formal_verification/verification_spec.md
```

## Status

Core contracts (Denylist, Vault) and the end-to-end runner are real, working code. Most other layers are design docs ready to be implemented. The meta-audit, formal verification, and key management layers are the newest additions.

## License

MIT