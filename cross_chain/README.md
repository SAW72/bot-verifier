# Cross-Chain Portability

Your attestation lives on Base. What happens when the bot moves to Solana or Ethereum?

## The problem
A fingerprint on one chain is a silo. If the bot's policy contract lives on Base but the bot runs on Solana, you have no portable proof.

## The fix
A portable attestation standard — a canonical fingerprint format that can be verified on any chain, with bridges or light clients to carry the proof.

## Files
- `portable_fingerprint.md` — the canonical format
- `bridge_design.md` — how proofs travel between chains
- `light_client_notes.md` — verifying without full nodes
- `cross_chain_bot_prompt.md` — Grok bot that tracks portability

The goal: one fingerprint, verifiable everywhere, no matter where the bot lives.