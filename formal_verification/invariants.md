# Formal Verification Invariants

These are the properties the Denylist and Vault contracts must satisfy.
Use with a tool like Certora, Slither, or manual review.

## Denylist.sol
1. `addExact`, `addSignature`, `addPrompt` are irreversible: once `denylistedX[h] == true`, no function can set it back to false.
2. `remove` always reverts.
3. `check` returns the highest MatchLevel present (Exact > Signature > Prompt > None).
4. No path allows a denylisted hash to pass `check` with `MatchLevel.None`.
5. Only `owner` can add entries.

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

## DisputePanel.sol
1. A dispute resolves only after >= 3 votes.
2. `upheld` is true iff `votesFor >= votesAgainst`.
3. No vote after resolution.
