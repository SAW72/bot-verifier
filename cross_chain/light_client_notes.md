# Light Client Notes

## What a light client does
Verifies block headers and event logs from another chain without running a full node. Enough to confirm that a specific attestation event happened on the source chain.

## Requirements
- Source chain block header verification (signatures, consensus).
- Event log inclusion proof.
- TEE attestation verification (the same check the source chain did).

## Trade-offs
- Full security requires trusting the source chain's consensus.
- For high-value bots, run a full node on the source chain instead.
- For most audits, a light client is sufficient and cheap.

## Starter recommendation
Start with EVM-to-EVM bridges. Add Solana support once the EVM path is proven.