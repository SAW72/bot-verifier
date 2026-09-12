# Hub-and-Spoke Architecture

## Goal
One canonical source of truth across every chain, with no single chain owning the verdict.

## Hub (canonical chain)
- Holds: denylist, vault registry, tier assignments, audit fingerprints, burn records.
- Run by a decentralized validator set staking on the hub chain.
- State updates are collectively signed. If the hub is compromised, spoke light clients stop accepting updates and the system freezes safe instead of failing open.

## Spokes (every other chain)
- Run a light client that mirrors hub state.
- Never decide on their own. Ask the hub: "is this bot denylisted?" and verify the cryptographic proof.
- Submit new records upward (new audit, denylist entry, burn) through a permissionless bridge.

## Two-way flow
- Spokes report up: audits, incidents, burns.
- Hub broadcasts down: denylist updates, tier changes, registry state.

## Tradeoff
Every cross-chain check adds a round trip. Fine for registration, access grants, denylist checks. Too slow for high-frequency trading.

## Security
- Hub validators stake and get slashed for equivocation or false state.
- Light clients verify proofs, not trust a relayer.
- No single operator can forge a denylist entry or revive a burned bot.
