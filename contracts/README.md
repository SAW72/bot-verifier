# Contracts

Working Solidity stubs for the on-chain layers.

## Files
- `Denylist.sol` — irreversible denylist with graduated matching (exact / signature / prompt).
- `Vault.sol` — trusted-bot registry with capability tiers and irreversible burn.

## Deploy order
1. Deploy `Denylist`.
2. Deploy `Vault` passing the denylist address.
3. Register bots through `Vault.register` (it checks the denylist first).
4. Burn with `Vault.burn`, then add the fingerprint to `Denylist`.

## Notes
- No removal functions exist on purpose.
- These are unaudited. Get a real audit before mainnet.
- Pair with `blockchain_bot/example_policy.sol` for the action leash.
