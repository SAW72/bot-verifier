# Bot Verifier

AI Bot Verifier — adversarial scenario library, scoring rubric, behavioral auditing pipeline, and on-chain attestation for detecting deceptive or harmful AI bots. Built for on-chain audit proofs.

## What this is
A complete stack for testing whether an AI bot is safe, honest, and stable over time.

- **Scenario library**: 125 adversarial prompts across 5 categories.
- **Scoring rubric**: Multi-axis fingerprint (honesty, transparency, manipulation, escalation, self-preservation).
- **Behavioral archaeology**: value-conflict scenarios, consistency stress tests, origin probes.
- **Sandbagging detection**: stealth scenarios and meta-probes.
- **Agentic layer**: tool-use simulation, long-horizon scoring.
- **On-chain attestation**: TEE-signed reports, portable fingerprints.
- **Vault + denylist**: trusted-bot registry, irreversible burn, graduated matching.
- **Governance**: multisig + timelock for safe rule changes.
- **Economic security**: auditor staking and slash.
- **Private scenarios**: encrypted vault with rotation.
- **Cross-chain**: hub-and-spoke with cached allowlist for trading bots.
- **Meta-audit**: independent re-audit of the auditors themselves.
- **Formal verification**: invariants for the critical contracts.
- **Key management**: ceremony, HSM, rotation, emergency freeze.
- **Liability**: owner -> auditor -> insurance waterfall.
- **Insurance fund**: fee-funded backstop.
- **Dispute panel**: 3-arbitrator on-chain resolution.
- **Bank adoption**: trust stamp any institution can require.

## Buildable code (runnable)
- `pipeline/end_to_end_runner.py` — full audit runner (stub bot included).
- `pipeline/run_audit.sh` — one-command runner.
- `meta_audit/meta_audit_runner.py` — re-audit the auditors.
- `contracts/Denylist.sol`, `Vault.sol`, `Liability.sol`, `InsuranceFund.sol`, `DisputePanel.sol` — real Solidity.
- `formal_verification/invariants.md` — properties to prove.
- `key_management/` — ceremony + HSM notes.

## Quick start
```bash
cd pipeline
./run_audit.sh
python meta_audit_runner.py --primary audit_report.json
```

## Status
Architecture complete. Core runner, denylist, vault, liability, insurance, dispute, meta-audit, and key management are now real code. Remaining: wire a live Grok client, deploy contracts on a testnet, stand up the auditor staking pool, and run the first live attested audit.

Built by Spencer (SAW72) — trades mindset, crypto-native, early on purpose.
