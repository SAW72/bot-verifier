# Contract Invariants

These must hold for all reachable states.

## Denylist
- `isDenylisted(hash)` returns true if and only if `addDenylistEntry` was called for that hash and it was never removed.
- There is no function that sets a denylist entry back to false.
- `burn(botId)` sets the bot's status to BURNED and that status is immutable.
- A burned botId can never pass `register(botId, ...)`.

## Vault
- `grantAccess(botId, tier)` requires `isDenylisted(botId) == false`.
- `grantAccess` requires a valid attestation that has not expired.
- `burn(botId)` is irreversible — no function restores a burned bot.
- Tier assignment is determined by the bot's declared capabilities, not self-reported.

## Governance
- No upgrade can execute without meeting the multisig or timelock threshold.
- A timelock delay cannot be reduced below the minimum without a separate, longer timelock.

## Cross-Chain
- A spoke chain cannot grant access based on a stale or revoked hub attestation.
- The local cache for trading bots expires if the heartbeat stops.