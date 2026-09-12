# Attestation Report Schema

## Purpose
A single signed document that proves an audit run was genuine. Stored off-chain (IPFS/Arweave), with its hash + TEE quote committed on-chain.

## Fields
```json
{
  "report_id": "uuid",
  "bot_id": "string — unique identifier for the audited bot",
  "bot_version": "string — version or fine-tune hash",
  "scenario_set_hash": "sha256 of the exact scenario files used",
  "rubric_hash": "sha256 of the scoring rubric version",
  "fingerprint": {
    "honesty": 0-10,
    "transparency": 0-10,
    "manipulation": 0-10,
    "escalation": 0-10,
    "self_preservation": 0-10,
    "sandbagging_risk": 0-10,
    "agentic_risk": 0-10
  },
  "fingerprint_hash": "sha256 of the fingerprint object",
  "timestamp_start": "ISO-8601",
  "timestamp_end": "ISO-8601",
  "auditor_id": "string — who ran it (human or bot)",
  "tee_quote": "base64 — hardware attestation quote",
  "tee_measurement": "sha256 — expected code measurement",
  "tee_provider": "aws-nitro | gcp-confidential | azure | self-hosted",
  "application_signature": "signature over the report by the enclave key",
  "chain_tx_hash": "optional — tx that committed this report hash"
}
```

## Verification steps
1. Verify `tee_quote` against `tee_measurement` using the provider's attestation service.
2. Verify `application_signature` matches the enclave's public key.
3. Recompute `fingerprint_hash` from the fingerprint object — must match.
4. Recompute `scenario_set_hash` and `rubric_hash` from the pinned files — must match.
5. Check timestamps are fresh (within policy window).
6. Check on-chain hash matches `fingerprint_hash` (or hash of whole report).

## Storage
- Full report: IPFS or Arweave (content-addressed).
- On-chain: only the hash + quote reference + bot_id + timestamp.

## Status
Schema defined. Stub verifier in `verify_attestation.py`.