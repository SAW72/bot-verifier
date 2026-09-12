# TEE Attestation Design

## Goal
Prove, to anyone on-chain or off-chain, that a specific audit fingerprint was produced by a specific bot running a specific scenario set, inside a trusted execution environment.

## What a TEE gives you
- **Code integrity**: the measurement (hash of the code + config) is fixed at boot. If anyone tampers with the runner, the quote fails.
- **Data confidentiality**: the scenario set and target bot responses can stay inside the enclave if needed.
- **Remote attestation**: the TEE produces a signed quote that a third party can verify against the expected measurement.

## Recommended providers (pick one)
- **AWS Nitro Enclaves** — EVM-friendly, cheap, good docs.
- **GCP Confidential Computing (Confidential VMs)** — straightforward, AMD SEV-SNP.
- **Azure Confidential Computing** — SGX or SEV options.
- **Self-hosted SGX/SEV** — maximum control, more ops burden.

## Flow
1. Boot the enclave with the audit runner + expected measurement.
2. Feed it: bot endpoint, scenario set, scoring rubric.
3. Runner executes, produces fingerprint.
4. Enclave signs: (bot_id, scenario_set_hash, fingerprint_hash, timestamp) with its attestation key.
5. Emit a **TEE quote** (hardware-signed) + the application signature.
6. Submit to chain: hash of the signed report + the quote.
7. Verifier checks: quote valid, measurement matches expected, signature valid, on-chain hash matches.

## What it does NOT prove
- That the bot is safe in every possible context.
- That the scenario set is complete.
- That the scoring rubric is perfect.

It proves the *run happened as claimed*. That's the missing link.

## Failure modes to watch
- **Quote replay**: an old valid quote reused. Mitigate with fresh nonces and timestamps.
- **Measurement drift**: code updated but measurement not updated. Mitigate with CI that recomputes and pins the expected measurement.
- **Side channels**: TEE does not eliminate all side channels. Keep sensitive data minimal inside the enclave.

## Next step
Pick a provider, write the enclave wrapper for `tool_calling_loop.py`, and run one real attested audit.