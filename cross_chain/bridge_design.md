# Bridge Design

## Approach: light client + message passing
1. Source chain (e.g. Base) emits an attestation event with the fingerprint hash.
2. A light client on the destination chain (e.g. Solana) verifies the source chain's block header.
3. The destination chain accepts the fingerprint as valid without re-running the audit.

## For EVM-to-EVM (Base to Ethereum)
- Use a canonical bridge or a simple relay contract.
- Verify the source block hash, then accept the event.

## For EVM-to-Solana
- Use a wormhole-style or custom light client.
- Verify the Base block, then post the fingerprint to a Solana program.

## Security
- Bridge must verify the TEE attestation, not just the hash.
- A compromised bridge cannot forge a fingerprint — the TEE signature still has to check out.

Keep it simple. The bridge carries proof, not intelligence.