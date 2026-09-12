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
- [ ] `forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts`
- [ ] Deploy core stack with `script/Deploy.s.sol` (`CORE_TIMELOCK` required; Liability then InsuranceFund for immutable `onlyLiability`)
- [ ] Deploy the additive BVT stack with `script/DeployBVT.s.sol` (agents do not `--broadcast`)
- [ ] Record addresses in `deployments/base-sepolia.json` and `contracts/README.md`
- [ ] Point the stamp API at those addresses
- [ ] Bootstrap operators via `BVTStaking.bootstrapOperator` — not a public sale

## Stage 3 — first institution
- [ ] One crypto-native bank / neobank / payment processor as anchor tenant
- [ ] They call `/v1/access/check` before granting a bot financial permissions
- [ ] One real incident drill: file a claim, run the waterfall on testnet

## What is NOT live yet
- TEE attestation against a real enclave
- Auditor staking and slash on mainnet
- Private scenario vault encryption at rest
- Cross-chain light clients
- Formal proofs in Certora (invariants are written; proofs are not)

Those are Stage 4. Do not wait for Stage 4 to start Stage 1.
