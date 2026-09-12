# Contracts

Working Solidity for the on-chain layers. **Testnet only.** Mainnet is refused by the deploy script.

## Files
- `Denylist.sol` — irreversible denylist with graduated matching (exact / signature / prompt).
- `Vault.sol` — trusted-bot registry with capability tiers and irreversible burn. Constructor: `Vault(denylist)`.
- `InsuranceFund.sol` — fee-funded backstop. No constructor args.
- `Liability.sol` — owner → auditor → insurance waterfall. Constructor: `Liability(insuranceFund)`.
- `DisputePanel.sol` — 3-arbitrator resolution. No constructor args.

## Deploy order (dependency-correct)

InsuranceFund must be created **before** Liability even though older notes listed Liability first.

1. `Denylist`
2. `Vault(denylist)`
3. `InsuranceFund`
4. `Liability(insuranceFund)`
5. `DisputePanel`

## Chainid guard

`script/Deploy.s.sol` enforces:

| Chain | ID | Allowed |
| --- | --- | --- |
| Base Sepolia | **84532** | yes (default) |
| Ethereum Sepolia | 11155111 | no, unless you change `ALLOWED_CHAIN_ID` |
| Ethereum mainnet | 1 | **always revert** (`Deploy: mainnet forbidden`) |
| anything else | — | revert |

To switch the script to Ethereum Sepolia, change `ALLOWED_CHAIN_ID` to `ETH_SEPOLIA_CHAIN_ID` (11155111). Do not remove the mainnet check.

## Spencer deploy (you broadcast; agents do not)

Keys and RPC come from the environment only. Never commit `PRIVATE_KEY`, paste it into a PR, or pass it on a recorded command line if you can avoid it.

```bash
# one-time
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install foundry-rs/forge-std

export BASE_SEPOLIA_RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
# PRIVATE_KEY is a Base Sepolia funded key — export it in your shell, do not commit it

# compile + local tests (no RPC, no key)
forge build
forge test

# simulate against Base Sepolia (no broadcast)
forge script script/Deploy.s.sol:Deploy --rpc-url "$BASE_SEPOLIA_RPC_URL"

# YOU run this. Agents must not --broadcast.
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast
```

Optional verify (needs a Basescan key in the environment, not the repo):

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast \
  --verify \
  --etherscan-api-key "$BASESCAN_API_KEY"
```

After a successful broadcast, paste addresses below. Do not commit `.env`.

## Base Sepolia addresses (84532)

Fill in after Spencer broadcasts `script/Deploy.s.sol`.

| Contract | Address | Tx |
| --- | --- | --- |
| Denylist | _pending Spencer deploy_ | |
| Vault | _pending Spencer deploy_ | |
| InsuranceFund | _pending Spencer deploy_ | |
| Liability | _pending Spencer deploy_ | |
| DisputePanel | _pending Spencer deploy_ | |

## Notes
- No denylist removal functions exist on purpose.
- These are unaudited. Get a real audit before any mainnet discussion.
- Pair with `blockchain_bot/example_policy.sol` for the action leash.
