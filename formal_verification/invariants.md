# Formal Verification Invariants

These are the properties the Denylist and Vault contracts must satisfy.
Use with a tool like Certora, Slither, or manual review.

## Denylist.sol
1. `remove(id, bucket)` clears `active` for that bucket only. `timesListed` never decreases, and `everListed` stays true after removal.
2. `bytes32(0)` cannot be added or removed.
3. `check` returns the strongest active MatchLevel (`ExactBlock` > `SignatureBlock` > `PromptBlock` > `None`). Ordinals stay 3, 2, 1, 0. `PromptBlock` is a hard block, the same gate as the other non-`None` levels.
4. An id with `active == false` does not produce a match, even if it was listed before. An id with `active == true` cannot produce `MatchLevel.None` for that bucket.
5. Only `owner` can add or remove. A second add while `active` reverts and does not bump `timesListed`.

## Vault.sol
1. `register` requires `denylist.check(...) == None`.
2. `burn` sets `active = false` and there is no `unburn` or revive function.
3. `grantAccess` returns false if `!active` or requested perms exceed tier cap.
4. A burned botId cannot be re-registered with the same id without a new registration flow (current impl blocks re-register).
5. Only `owner` can register or burn.

## Liability.sol
1. `settle` can be called only once per claimId (`paid` flag).
2. Waterfall order: Owner, then Auditor, then Insurance.
3. Insurance payout requires sufficient `InsuranceFund.balance`.
4. No double-claim on the same `incidentHash`.
5. `Party.Auditor` settle reverts until a slash/escrow hook exists (`Liability: auditor slash/escrow unset`) and does not set `paid`.

## InsuranceFund.sol
1. `payout` succeeds only when `msg.sender == liability` (`onlyLiability`).
2. `liability` is immutable and non-zero.
3. Owner / random EOAs / other contracts cannot `payout`.

## DisputePanel.sol
1. A dispute resolves only after >= 3 votes.
2. `upheld` is true iff `votesFor >= votesAgainst`.
3. No vote after resolution.
4. `vote` reverts unless the caller is an allowlisted arbitrator (`isArbitrator`).
