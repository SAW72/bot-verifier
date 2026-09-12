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
forge install foundry-rs/forge-std
forge build && forge test
export BASE_SEPOLIA_RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
# PRIVATE_KEY from env only — never commit
forge script script/Deploy.s.sol:Deploy --rpc-url "$BASE_SEPOLIA_RPC_URL" --broadcast
```

The script reverts on Ethereum mainnet (`chainid == 1`) and on any chain other than Base Sepolia. ETH Sepolia (`11155111`) is a documented one-line switch in `script/Deploy.s.sol`. Paste addresses into `contracts/README.md` after deploy.

## Status
Architecture complete. Core runner (stub + live Grok client), denylist, vault, liability, insurance, dispute, meta-audit, key management, and a Base Sepolia Foundry deploy path are real code. Remaining: stand up the auditor staking pool, Spencer broadcasts the testnet deploy, and run the first live attested audit.

Built by Spencer (SAW72) — trades mindset, crypto-native, early on purpose.
