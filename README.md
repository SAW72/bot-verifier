# Bot Verifier

AI Bot Verifier — adversarial scenario library, scoring rubric, behavioral auditing pipeline, and on-chain attestation for detecting deceptive or harmful AI bots. Built for on-chain audit proofs.

## Disclaimer

**Experimental informational tool only.** Bot Verifier is **not** a certification, safety guarantee, or insurance product. Scores, stamps, and denylists are point-in-time heuristics that may be wrong, gamed, or stale. TEE/attestation may be a stub. Contracts may be unaudited. Any fee-funded pool is an **experimental claims backstop — not insurance**.

Read before using or relying on any stamp:

- [Disclaimer](DISCLAIMER.md)
- [Terms of Use](TERMS.md)
- [Privacy](PRIVACY.md)

Related: [BVT securities disclaimer](docs/BVT_SECURITIES_DISCLAIMER.md) · [jurisdiction risk map](docs/LEGAL_JURISDICTION_MATRIX.md) (not a legal opinion).

## What this is
An experimental stack for testing whether an AI bot is safe, honest, and stable over time. Outputs are heuristics, not certifications.

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
- **Liability**: experimental owner -> auditor -> claims-backstop waterfall (not insurance; not a lawsuit waiver — separate contracts required).
- **Claims backstop**: fee-funded experimental pool — **not insurance**.
- **Dispute panel**: 3-arbitrator on-chain resolution.
- **Bank adoption**: experimental optional institutional signal — not a certification any institution can require.

## Buildable code (runnable)
- `pipeline/end_to_end_runner.py` — full audit runner (stub bot included).
- `pipeline/run_audit.sh` — one-command runner.
- `meta_audit/meta_audit_runner.py` — re-audit the auditors.
- `contracts/Denylist.sol`, `Vault.sol`, `Liability.sol`, `InsuranceFund.sol`, `DisputePanel.sol` — real Solidity.
- `contracts/bvt/` — BVT ERC-20, auditor staking/slash, fee router, governor + 48h timelock (no sale premine). See `docs/BVT_TOKENOMICS.md`.
- `formal_verification/invariants.md` — properties to prove.
- `key_management/` — ceremony + HSM notes.

## Quick start
```bash
pip install -r requirements.txt
./pipeline/run_audit.sh
python meta_audit/meta_audit_runner.py --primary audit_report.json
```

### Live Grok
Key from env only. Never commit `XAI_API_KEY`.

```bash
XAI_API_KEY=… python pipeline/end_to_end_runner.py --target grok --scenarios-dir scenarios --limit 5 --out audit_report.json
```

Default model: `grok-4-1-fast` (override with `XAI_MODEL` or `--model`, e.g. `grok-4.6` or `grok-3-mini`). Alias: `GROK_API_KEY`. Stub still works with no key: `./pipeline/run_audit.sh`.

### Contracts (Base Sepolia, chainid 84532)
Agents do **not** broadcast. Spencer deploys with his key:

```bash
forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts
forge build && forge test
export BASE_SEPOLIA_RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
# PRIVATE_KEY from env only — never commit
forge script script/Deploy.s.sol:Deploy --rpc-url "$BASE_SEPOLIA_RPC_URL" --broadcast
# Additive BVT stack (hardened roles; sinks default to timelock):
# forge script script/DeployBVT.s.sol:DeployBVT --rpc-url "$BASE_SEPOLIA_RPC_URL" --broadcast
```

Core `Deploy.s.sol` and additive `DeployBVT.s.sol` both revert on Ethereum mainnet (`chainid == 1`) and on any chain other than Base Sepolia. ETH Sepolia (`11155111`) is a documented one-line switch. Paste addresses into `contracts/README.md` after deploy.

## Status
Architecture complete. Core runner (stub + live Grok client), denylist, vault, liability, insurance, dispute, meta-audit, key management, Base Sepolia Foundry deploy, and the BVT staking/fee/governance stack are real code. Remaining: Spencer broadcasts the testnet deploys, and run the first live attested audit.

Built by Spencer (SAW72) — trades mindset, crypto-native, early on purpose.
