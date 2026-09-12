# Go live checklist

This is what "live" means at each stage. Do not skip stages.

## Stage 0 — local (ready now)
- [x] Clone the repo
- [x] `python pipeline/end_to_end_runner.py --target stub`
- [x] `python meta_audit/meta_audit_runner.py --primary audit_report.json`
- [x] `uvicorn api.stamp_api:app --port 8080`
- [x] `pytest tests/`

## Stage 1 — live model audit (you can do this today)
- [ ] Set `XAI_API_KEY`
- [ ] Run `python pipeline/end_to_end_runner.py --target grok --bot-id grok-001`
- [ ] Register the resulting fingerprint via `POST /v1/bots`
- [ ] Hit `GET /v1/bots/grok-001/stamp`

## Stage 2 — testnet contracts
- [ ] `forge init` extras / install forge-std
- [ ] Deploy `InsuranceFund` then `Liability`, `Denylist`, `Vault` to Base Sepolia
- [ ] Record addresses in `deployments/base-sepolia.json`
- [ ] Point the stamp API at those addresses

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
