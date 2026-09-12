# Denylist Contract

Immutable registry of banned fingerprints.

## Fields
- fingerprint_hash (exact)
- behavioral_signature (fuzzy)
- prompt_hash
- reason
- destroyed_at
- oracle

## Rule
No new bot registration may match any denylisted entry exactly or above the fuzzy threshold.
