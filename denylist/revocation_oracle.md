# Revocation Oracle

Triggers the denylist write when a bot is burned.

## Options
- Governance multisig
- DAO vote
- Trusted auditor committee

## Rule
Writes and removals are owner actions. On the live Denylist that owner is CORE_TIMELOCK (Ownable2Step). Removing an entry clears active membership only. `everListed` and the `Listed` / `Unlisted` events remain. There is no hot EOA path in the production ownership record.
