# Trust Stamp Specification

## Purpose
A trust stamp is the portable proof a bank checks before granting a bot access.

## Stamp Contents
- botId (unique, permanent)
- category and tier
- latest audit fingerprint hash
- attestation signature from the hub
- denylist status (clean / flagged / burned)
- insurance coverage level
- expiry timestamp
- chain of origin

## Stamp Format
JSON Web Token (JWT) signed by the hub's attestation key, or an on-chain attestation record referenced by hash.

## Verification Flow
1. Bank receives botId from a user or integration.
2. Bank calls `GET /v1/bots/{botId}/stamp`.
3. System returns the stamp + current denylist status.
4. Bank verifies the signature against the hub's public key.
5. Bank checks tier meets its policy.
6. Bank grants or denies access.

## Revocation
If a bot is denylisted or burned after the stamp is issued, the stamp is immediately invalid. Banks must re-check on every access grant, or cache with a short TTL (see cross_chain/local_cache_for_trading.md).
