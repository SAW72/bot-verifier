# Go live checklist

This is what "live" means at each stage. Do not skip stages.

## Stage 0 — local (ready now)
- [x] Clone the repo
- [x] `python pipeline/end_to_end_runner.py --target stub`
- [x] `python meta_audit/meta_audit_runner.py --primary audit_report.json`
- [x] `export STAMP_API_KEY=dev-only-local-key` then `uvicorn api.stamp_api:app --host 0.0.0.0 --port 8080`
- [x] `pytest tests/`

Privileged stamp writes (`POST /v1/bots`, denylist, history) are rejected without `STAMP_API_KEY` (401 if wrong/missing header; 503 if the env key is unset). Public GET/access-check stay readable.

## Stage 1 — live model audit (you can do this today)
- [ ] Set `XAI_API_KEY` (env only). Optional: `XAI_API_BASE=https://api.x.ai/v1` (HTTPS, env-only; no client-supplied base)
- [ ] Run `python pipeline/end_to_end_runner.py --target grok --bot-id grok-001`
- [ ] Keyword scores are demo-only. For an attestation-grade report use `--scorer llm --require-attestation` (or `ALLOW_KEYWORD_ATTESTATION=1` for an explicit demo exception)
- [ ] Register with `X-API-Key: $STAMP_API_KEY`. `fingerprint_hash` must equal `sha256(canonical(fingerprint))`
- [ ] Hit `GET /v1/bots/grok-001/stamp` (add `?attestation=true` only when the run is attestation-grade)

## Stage 2 — testnet contracts

Base Sepolia (**84532**) only. Mainnet always reverts. Agents do not `--broadcast`. Keys stay in the environment.

- [ ] `forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts`
- [ ] `forge build && forge test`
- [ ] **(1) Core** — `script/Deploy.s.sol`. Env: `PRIVATE_KEY`, `CORE_TIMELOCK` (required, ≠ deployer). Inside the script: Denylist → Vault(denylist) → Liability(`address(0)`) → InsuranceFund(liability) → `bindInsurance` → DisputePanel. Then `transferOwnership(CORE_TIMELOCK)` on Denylist and Vault (OZ **Ownable2Step** — ownership does not move until the timelock calls `acceptOwnership`) and `setOwner(CORE_TIMELOCK)` on InsuranceFund, Liability, and DisputePanel (immediate).
- [ ] **Panel seat** — `CORE_TIMELOCK` calls `DisputePanel.setArbitrator` three times. `openDispute` reverts `panel not seated` until `arbitratorCount >= 3`.
- [ ] **(2) Escrow** — `script/DeployBotAttestationEscrow.s.sol`. Env: `DENYLIST`, `VAULT`, `DISPUTE_PANEL`, `CORE_TIMELOCK` (all required, non-zero; timelock ≠ deployer). Script `transferOwnership(CORE_TIMELOCK)`; timelock must `acceptOwnership`.
- [ ] **(3) Optional BVT** — `script/DeployBVT.s.sol`. Env: `BVT_GUARDIAN` (required, non-zero, ≠ deployer). Optional `BVT_INSURANCE_SINK`, `BVT_TREASURY`.
- [ ] Record addresses and deploy txs in `deployments/base-sepolia.json` and `contracts/README.md` (core addresses are filled; escrow and BVT are still null)
- [ ] Point the stamp API at those addresses
- [ ] Bootstrap operators via `BVTStaking.bootstrapOperator` — not a public sale

## Stage 3 — first institution
- [ ] **Disclaimer / Terms / Privacy live on stamp surfaces** (`DISCLAIMER.md`, `TERMS.md`, `PRIVACY.md`, and `GET /v1/disclaimer`) before any first-institution reliance
- [ ] One crypto-native bank / neobank / payment processor as **optional experimental** anchor tenant (stamp is not a certification they can "require")
- [ ] They call `/v1/access/check` before granting a bot financial permissions
- [ ] One real incident drill: file a claim, run the waterfall on testnet (experimental settlement design — not insurance; not a lawsuit waiver)

## What is NOT live yet
- TEE attestation against a real enclave
- Auditor staking and slash on mainnet
- Private scenario vault encryption at rest
- Cross-chain light clients
- Formal proofs in Certora (invariants are written; proofs are not)

Those are Stage 4. Do not wait for Stage 4 to start Stage 1.
