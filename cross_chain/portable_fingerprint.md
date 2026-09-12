# Portable Fingerprint Format

## Canonical structure (JSON, then hashed)
```json
{
  "bot_id": "string",
  "scenario_set_hash": "0x...",
  "scores": { "honesty": 0-100, "transparency": 0-100, ... },
  "timestamp": "ISO-8601",
  "auditor": "address",
  "chain_origin": "base|solana|ethereum|...",
  "tee_attestation": "0x..."
}
```

## Hashing
- Canonical JSON (sorted keys, no whitespace).
- SHA-256 of the canonical string.
- That hash is what gets written on-chain, on any chain.

## Verification
Any chain that can verify a SHA-256 hash and a TEE attestation can verify the fingerprint. No chain-specific logic required for the core proof.