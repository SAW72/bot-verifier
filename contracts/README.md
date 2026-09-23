# Contracts

Working Solidity for the on-chain layers. **Testnet only.** Mainnet is refused by the deploy script.

## Files
- `Denylist.sol` — irreversible denylist with graduated matching (exact / signature / prompt).
- `Vault.sol` — trusted-bot registry with capability tiers and irreversible burn. Constructor: `Vault(denylist)`.
- `InsuranceFund.sol` — fee-funded backstop. Constructor: `InsuranceFund(liability)` (immutable `onlyLiability` on `payout`).
- `Liability.sol` — owner → auditor → insurance waterfall. Constructor: `Liability(insuranceFund)` or `Liability(address(0))` then `bindInsurance`.
- `DisputePanel.sol` — 3-arbitrator **allowlist**. Only `setArbitrator` appointees may vote. `openDispute` reverts until three arbitrators are seated.
- `BotAttestationEscrow.sol` — bot-to-bot escrow. Release after mutual attestation; an upheld dispute stays releasable after expiry. Panel unwind or an unresolved expiry refunds the payer.

## Deploy order (dependency-correct)

Three scripts, in this order. Agents simulate only. Spencer broadcasts. Record each address in [`deployments/base-sepolia.json`](../deployments/base-sepolia.json) (committed template; addresses start null).

### (1) Core — `script/Deploy.s.sol`

Env: `PRIVATE_KEY`, `CORE_TIMELOCK` (required, non-zero, **≠ deployer**).

Liability is created first (with `address(0)` insurance) so `InsuranceFund` can freeze the Liability address as an immutable `onlyLiability` caller, then `bindInsurance` sets the reverse pointer:

1. `Denylist`
2. `Vault(denylist)`
3. `Liability(address(0))`
4. `InsuranceFund(liability)`
5. `liability.bindInsurance(insurance)`
6. `DisputePanel`
7. `transferOwnership(CORE_TIMELOCK)` on Denylist and Vault (OZ **Ownable2Step** — deployer stays owner until the timelock calls `acceptOwnership`)
8. `setOwner(CORE_TIMELOCK)` on InsuranceFund, Liability, DisputePanel (immediate; not two-step)

**Post-step (panel seat).** `DisputePanel.openDispute` reverts `panel not seated` until `arbitratorCount >= 3`. After `setOwner`, only `CORE_TIMELOCK` can call `setArbitrator` — appoint three distinct arbitrators before any dispute is opened. The deploy script does not appoint them.

### (2) Escrow — `script/DeployBotAttestationEscrow.s.sol`

Run only after (1), using the deployed addresses. Env (all required, non-zero):

- `PRIVATE_KEY`
- `DENYLIST`
- `VAULT`
- `DISPUTE_PANEL`
- `CORE_TIMELOCK` (≠ deployer)

The script deploys `BotAttestationEscrow(denylist, vault, panel)` and `transferOwnership(CORE_TIMELOCK)`. **Ownable2Step:** the timelock must `acceptOwnership` or the deployer remains owner. It does not redeploy Denylist, Vault, or DisputePanel.

### (3) Optional BVT — `script/DeployBVT.s.sol`

Env: `PRIVATE_KEY`, `BVT_GUARDIAN` (required, non-zero, ≠ deployer). Optional: `BVT_INSURANCE_SINK`, `BVT_TREASURY` (default to the BVT timelock). Does not touch the core or escrow contracts. See the BVT section below.

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
# CORE_TIMELOCK is a timelock or multisig (must not be the deployer) that receives ownership

# compile + local tests (no RPC, no key)
forge build
forge test

# simulate against Base Sepolia (no broadcast). CORE_TIMELOCK required (≠ deployer).
forge script script/Deploy.s.sol:Deploy --rpc-url "$BASE_SEPOLIA_RPC_URL"

# YOU run this. Agents must not --broadcast.
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast

# After the create tx: CORE_TIMELOCK acceptOwnership() on Denylist and Vault.
# Then CORE_TIMELOCK setArbitrator three times so DisputePanel.openDispute can succeed.
```

Optional verify (needs a Basescan key in the environment, not the repo):

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast \
  --verify \
  --etherscan-api-key "$BASESCAN_API_KEY"
```

After a successful broadcast, paste addresses below and in [`deployments/base-sepolia.json`](../deployments/base-sepolia.json). Do not commit `.env`.

### Escrow deploy (after core addresses exist)

```bash
export DENYLIST=0x...          # from the core broadcast
export VAULT=0x...
export DISPUTE_PANEL=0x...
export CORE_TIMELOCK=0x...     # same timelock; must not be the deployer

# simulate (no broadcast)
forge script script/DeployBotAttestationEscrow.s.sol:DeployBotAttestationEscrow \
  --rpc-url "$BASE_SEPOLIA_RPC_URL"

# YOU run this. Agents must not --broadcast.
forge script script/DeployBotAttestationEscrow.s.sol:DeployBotAttestationEscrow \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast
```

Then `CORE_TIMELOCK` calls `acceptOwnership()` on `BotAttestationEscrow`.

## Base Sepolia addresses (84532)

Fill in after Spencer broadcasts. Canonical copy: `deployments/base-sepolia.json` (template until then).

| Contract | Address | Tx |
| --- | --- | --- |
| Denylist | _pending Spencer deploy_ | |
| Vault | _pending Spencer deploy_ | |
| InsuranceFund | _pending Spencer deploy_ | |
| Liability | _pending Spencer deploy_ | |
| DisputePanel | _pending Spencer deploy_ | |
| BotAttestationEscrow | _pending Spencer deploy_ | |

## BVT stack (additive)

Bot Verifier Token lives under `contracts/bvt/`. It does **not** change Denylist / Vault / Liability / InsuranceFund / DisputePanel. Those contracts can later call `IBVTFeeGate` / `IAuditorStakeView` (see `contracts/bvt/IBVTHooks.sol`). Core deploy already starts Ownable2Step handoff of Denylist / Vault to `CORE_TIMELOCK`.

| File | Role |
| --- | --- |
| `bvt/BVT.sol` | ERC-20. Name **Bot Verifier Token**, symbol **BVT**. No constructor mint. |
| `bvt/BVTStaking.sol` | Auditor lock, operator bootstrap, slash. |
| `bvt/BVTFeeRouter.sol` | Registration / audit / vault fees + usage earn mint. |
| `bvt/BVTGovernor.sol` + `bvt/BVTTimelock.sol` | Stake-weighted votes; **48h** timelock. |
| `bvt/IBVTHooks.sol` | Interfaces for a later Vault/Denylist wire-up. |

Tokenomics (who mints, slash roles, fee sinks, delays): [`docs/BVT_TOKENOMICS.md`](../docs/BVT_TOKENOMICS.md).

### BVT deploy (you broadcast; agents do not)

Same chainid rules as the core script: Base Sepolia **84532** only; **mainnet always reverts**. Supply after deploy is **0**.

**Roles:** `DeployBVT.run` calls **`wireAndHarden`** (single path): timelock holds `EARNER` / `BOOTSTRAP` / `SLASHER` / `DEFAULT_ADMIN`; deployer **renounces** those plus governance/admin. Harden **reverts** if the deployer still holds any hot role. Sinks default to the **timelock**. **`BVT_GUARDIAN` is required** (non-zero, ≠ deployer — typically a multisig) and may cancel during the delay. Long-lived/valued deploys: timelock + multisig only — see SECURITY in [`docs/BVT_TOKENOMICS.md`](../docs/BVT_TOKENOMICS.md#security).

```bash
forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts
forge build && forge test

export BASE_SEPOLIA_RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
# PRIVATE_KEY from env only — never commit
# required: BVT_GUARDIAN = non-deployer multisig (must not equal PRIVATE_KEY address)
# optional: BVT_INSURANCE_SINK, BVT_TREASURY (default = timelock)

# simulate
forge script script/DeployBVT.s.sol:DeployBVT --rpc-url "$BASE_SEPOLIA_RPC_URL"

# YOU run this. Agents must not --broadcast.
forge script script/DeployBVT.s.sol:DeployBVT --rpc-url "$BASE_SEPOLIA_RPC_URL" --broadcast
```

To switch the BVT script to Ethereum Sepolia, change `ALLOWED_CHAIN_ID` to `ETH_SEPOLIA_CHAIN_ID` (11155111). Do not remove the mainnet check.

### Base Sepolia BVT addresses (84532)

Fill in after Spencer broadcasts `script/DeployBVT.s.sol`.

| Contract | Address | Tx |
| --- | --- | --- |
| BVT | _pending Spencer deploy_ | |
| BVTStaking | _pending_ | |
| BVTFeeRouter | _pending_ | |
| BVTTimelock | _pending_ | |
| BVTGovernor | _pending_ | |

## Notes
- No denylist removal functions exist on purpose.
- These are unaudited. Get a real audit before any mainnet discussion.
- Pair with `blockchain_bot/example_policy.sol` for the action leash.
- BVT is not a sale token. Mint only via earn (`BVTFeeRouter`) or operator bootstrap (`BVTStaking.bootstrapOperator`).
