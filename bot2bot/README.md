# Bot-to-Bot Handshake

Lets one attested bot verify another before paying it. The payer checks the
payee's stamp (attestation-grade, fresh, not denylisted, tier sufficient),
then optionally opens an on-chain escrow that holds funds until both sides
pass the same check.

## Flow

1. **Payer bot** calls `verify_counterparty(stamp_api, payee_bot_id)`.
2. If allowed, payer creates an escrow on `BotAttestationEscrow` with both
   bot ids and the amount.
3. Either side (or a watcher) calls `release(escrowId)` once both bots are
   active, Financial-tier or above, and clean on the denylist.
4. `refund` returns funds to the payer if the escrow expires with no upheld
   dispute, or if the panel rules an unwind. An upheld dispute pays the payee
   via `release`, including after `expiresAt`. `refund` reverts in that case.

## Files

- `contracts/BotAttestationEscrow.sol` — escrow contract (Solidity).
- `bot2bot/handshake.py` — Python client + `verify_counterparty`.
- `bot2bot/__init__.py` — package exports.

## Why this matters

Without this layer, attestation is a stamp on a wall. With it, the stamp is
enforced at the moment of value transfer — bots that only deal with attested
peers rise, unattested ones get priced out.
