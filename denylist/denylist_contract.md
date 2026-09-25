# Denylist Contract

Governed registry of banned fingerprints. Active membership is owner-gated and reversible. History is not.

## Fields
- fingerprint hash, behavioral signature, or prompt hash, each in its own bucket
- `active` — current membership
- `timesListed`, `firstListedAt`, `lastListedAt`, `lastUnlistedAt`
- `lastListedBy`, `lastUnlistedBy`

## Rule
No new bot registration or escrow verification may pass while `check` is anything other than `None`. Exact, signature, and prompt matches are all hard blocks (`ExactBlock`, `SignatureBlock`, `PromptBlock`).

`remove` clears `active` for one bucket. `timesListed` stays, so a later reader can still see that the id was listed. Only the owner can add or remove. `bytes32(0)` is rejected.
