# BotAttestationEscrow on Base Sepolia

`BotAttestationEscrow` is **live** on Base Sepolia against the live core stack. Gate B is **seated** on the live `DisputePanel` (`arbitratorCount` is 3). This file records that state. It does not deploy anything by itself.

**SIMULATE is not live.** `forge script` without `--broadcast` forks Base Sepolia and prints the calls. Nothing is sent. A green simulation is not a deployment. Do not paste a simulated address over the live book.

**HARD STOP**

- Agents do not pass `--broadcast` or `--resume`.
- Do not touch Ethereum mainnet. Every script here reverts on chainid `1`.
- Do not redeploy Denylist or Vault. Gate A is done. Use the live addresses below.
- Do not redeploy `BotAttestationEscrow`. The live address is already in the book.
- Do not deploy BVT in this pack.
- Do not call `createEscrow` from an agent session.

Escrow bytecode on `main` already includes the H-1 fix (upheld release skips post-ruling attestation). This pack does not change Denylist, Vault, or Escrow bytecode.

Landed order: Gate B was seated (block 47299643), then escrow was created and `transferOwnership` ran (block 47299930), then `CORE_TIMELOCK` called `acceptOwnership` (block 47300275).

## Live addresses (chainid 84532)

| Role | Address |
| --- | --- |
| Denylist | `0xeE76876bECcFc1B58fC06fF4E654a517d784B224` |
| Vault | `0x1463D664fA467FBCDA4B05443434494f05e565bc` |
| DisputePanel | `0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb` |
| BotAttestationEscrow | `0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c` |
| CORE_TIMELOCK | `0x10CC9474b45625ADfd05C209f2518023484878D9` |

`BotAttestationEscrow.owner()` is `CORE_TIMELOCK`. `pendingOwner` is the zero address. `acceptOwnership` is complete.

`DisputePanel.owner()` is `CORE_TIMELOCK`. Gate B is seated: `arbitratorCount` is **3**. `openDispute` reverts `panel not seated` only if that count later drops below 3.

| # | Arbitrator | Seat tx (block 47299643) |
| --- | --- | --- |
| 1 | `0xD5ee9fA366C3698b34204722c635989E5197B018` | `0xa97b518ad87489ab1d45ec4bef5e548c1d4bf3b9c940552e8cba1752fed7553c` |
| 2 | `0xF4253A3a3C102Ee59e38b2AA92989C3232eDcC30` | `0xf1ad4d9221b2393863d9bc6a72c1a716cf389532d2cfa63fd4df682303ed6df6` |
| 3 | `0xB87Ed5F74276AC6172ef53fE866675093F75936E` | `0xa1f8f0fb6ad78dd2d9fd9d33dabf9cde5b73195a1b292869e7d96cc985cb79a3` |

Escrow create tx `0x700d9bac95e8833bd7e93721a88d689a0fb839c9e6108858c52560eae111948e` and `transferOwnership` tx `0x00aaef315f23de346bfe63e77e0f04d3fbcadc370b0db21bb7abb8f8e12c40f2` are both block 47299930. `acceptOwnership` tx `0xd2e982568811c3706eec074d296ef7fa4c54838de714e1a5bfc8afc9fbb73983` is block 47300275. The escrow is linked to DisputePanel `0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb`. Canonical copy: [`deployments/base-sepolia.json`](../deployments/base-sepolia.json).

`CORE_TIMELOCK` is the same account that owns the live Denylist and Vault. On chain its code is an EIP-7702 delegation, not an OpenZeppelin `TimelockController` (`schedule` / `getMinDelay` are absent). `onlyOwner` is `msg.sender == owner()`. A transaction whose sender is `CORE_TIMELOCK` is the owner call. See [`script/OPS_LIVE_DENYLIST_VAULT.md`](OPS_LIVE_DENYLIST_VAULT.md).

Liability `0x554Caf5a214B8d70D675C09186C5EAE24FEB7307` and InsuranceFund `0x19fc26B36Cb2031062eD90C19db64b3b09753ab8` stay as they are. This pack does not call them.

## Escrow simulate env

`script/DeployBotAttestationEscrow.s.sol` reads these. All addresses are required and non-zero. `CORE_TIMELOCK` must not equal the deployer address derived from `PRIVATE_KEY`. Never commit `PRIVATE_KEY`.

```bash
export BASE_SEPOLIA_RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
# PRIVATE_KEY is a Base Sepolia deployer key in your shell. It is not CORE_TIMELOCK.
# Do not paste it into a PR, a log, or this file.
export PRIVATE_KEY
export DENYLIST=0xeE76876bECcFc1B58fC06fF4E654a517d784B224
export VAULT=0x1463D664fA467FBCDA4B05443434494f05e565bc
export DISPUTE_PANEL=0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb
export CORE_TIMELOCK=0x10CC9474b45625ADfd05C209f2518023484878D9
```

| Variable | Meaning |
| --- | --- |
| `PRIVATE_KEY` | Deployer key for the escrow **create**. Required for simulate and for Spencer's broadcast. Must not be `CORE_TIMELOCK`. |
| `DENYLIST` | Live Denylist above. The script does not redeploy it. |
| `VAULT` | Live Vault above. The script does not redeploy it. |
| `DISPUTE_PANEL` | Live DisputePanel above. |
| `CORE_TIMELOCK` | Immutable escrow `governance`. On the live escrow it is `owner()`; `pendingOwner` is zero. |
| `BASE_SEPOLIA_RPC_URL` | Base Sepolia RPC. Chainid must be `84532`. |

## Escrow simulate (not live)

```bash
forge script script/DeployBotAttestationEscrow.s.sol:DeployBotAttestationEscrow \
  --rpc-url "$BASE_SEPOLIA_RPC_URL"
```

There is no `--broadcast` on that command. The log line is a dry run. The address printed for `BotAttestationEscrow` exists only inside that process. Do not paste it into the address book.

## Escrow broadcast (already landed; Spencer only)

This broadcast already landed. Agents must not run it again. A second broadcast deploys a second escrow. Do not replace the live address.

```bash
forge script script/DeployBotAttestationEscrow.s.sol:DeployBotAttestationEscrow \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast
```

Chain guard: chainid `1` reverts `DeployEscrow: mainnet forbidden`. Any chain other than `84532` reverts. There is no Ethereum Sepolia switch unless someone edits `ALLOWED_CHAIN_ID` on purpose. Do not.

## Escrow ownership (complete)

1. `CORE_TIMELOCK` has called `acceptOwnership()` on `BotAttestationEscrow` `0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c`. `owner` is `CORE_TIMELOCK`. `pendingOwner` is the zero address. The accept tx is `0xd2e982568811c3706eec074d296ef7fa4c54838de714e1a5bfc8afc9fbb73983` (block 47300275).
2. The address and create-tx hash are in `BotAttestationEscrow.address` and `BotAttestationEscrow.deployTx` in [`deployments/base-sepolia.json`](../deployments/base-sepolia.json) and in the table in [`contracts/README.md`](../contracts/README.md).
3. `setDenylist`, `setVault`, and `setDisputePanel` revert unless `owner() == governance`, and they revert while `lockedValue != 0`.

`acceptOwnership` was an owner-to-be call from `CORE_TIMELOCK`, same as Gate A on Denylist and Vault. It is not part of the deploy script. Agents do not send it again.

## Gate B — seated

Gate B is seated. `arbitratorCount` is 3. The three arbitrators and seat txs are in the live-address section above. `openDispute` reverts `panel not seated` if `arbitratorCount` drops below 3. The escrow deploy script does not appoint arbitrators. The ops scripts below call the live panel only. They do not deploy a new panel. Agents do not `--broadcast` them.

Same broadcast rule as [`OpsDenylist`](OpsDenylist.s.sol) / [`OpsVault`](OpsVault.s.sol): dry-run `prank`s `CORE_TIMELOCK` and does not read `PRIVATE_KEY`. `--broadcast` and `--resume` revert with `OpsLive: PRIVATE_KEY is not the live owner; Spencer only` unless that key's address is `CORE_TIMELOCK`.

The three live seats are already on the panel. The placeholders below are for a future add or remove. They are not the seated arbitrators. Replace them before any new panel op.

```bash
export BASE_SEPOLIA_RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
export DISPUTE_PANEL=0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb
export CORE_TIMELOCK=0x10CC9474b45625ADfd05C209f2518023484878D9

# Replace. These are documentation placeholders, not live arbitrators.
export ARBITRATOR_1=0x0000000000000000000000000000000000000A11
export ARBITRATOR_2=0x0000000000000000000000000000000000000A22
export ARBITRATOR_3=0x0000000000000000000000000000000000000A33
```

| Variable | Used by | Meaning |
| --- | --- | --- |
| `DISPUTE_PANEL` | every panel op | Must be the live panel above. Any other address reverts. |
| `CORE_TIMELOCK` | every panel op | Must be the live owner above, and must equal `owner()`. |
| `ARBITRATOR` | add and remove | One address. |
| `ARBITRATOR_1`, `ARBITRATOR_2`, `ARBITRATOR_3` | seat | Three distinct non-zero addresses. |
| `PRIVATE_KEY` | Spencer `--broadcast` only | Must be the key for `CORE_TIMELOCK`. Omit it for simulate. |

### Simulate (not live)

The log line `SIMULATE; no transaction will be sent` is the dry run.

```bash
# Preferred Gate B batch. Three setArbitrator(account, true) calls.
forge script script/OpsDisputePanel.s.sol:OpsDisputePanelSeat \
  --rpc-url "$BASE_SEPOLIA_RPC_URL"

# One add, or one remove.
export ARBITRATOR="$ARBITRATOR_1"
forge script script/OpsDisputePanel.s.sol:OpsDisputePanelAdd \
  --rpc-url "$BASE_SEPOLIA_RPC_URL"
forge script script/OpsDisputePanel.s.sol:OpsDisputePanelRemove \
  --rpc-url "$BASE_SEPOLIA_RPC_URL"
```

Accounts that already have the requested allowlist bit are skipped. No empty transaction is built for them.

### Broadcast (Spencer only)

Agents must not run this. The signer must be `CORE_TIMELOCK`. A deployer key reverts before `startBroadcast`.

```bash
forge script script/OpsDisputePanel.s.sol:OpsDisputePanelSeat \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast
```

One address at a time, still Spencer-only:

```bash
export ARBITRATOR="$ARBITRATOR_1"
forge script script/OpsDisputePanel.s.sol:OpsDisputePanelAdd \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast

forge script script/OpsDisputePanel.s.sol:OpsDisputePanelRemove \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast
```

### Reads and calldata

```bash
cast call "$DISPUTE_PANEL" "owner()(address)" --rpc-url "$BASE_SEPOLIA_RPC_URL"
cast call "$DISPUTE_PANEL" "arbitratorCount()(uint256)" --rpc-url "$BASE_SEPOLIA_RPC_URL"
cast call "$DISPUTE_PANEL" "isArbitrator(address)(bool)" "$ARBITRATOR_1" --rpc-url "$BASE_SEPOLIA_RPC_URL"

cast calldata "setArbitrator(address,bool)" "$ARBITRATOR_1" true
cast calldata "setArbitrator(address,bool)" "$ARBITRATOR_1" false
```

Spencer send, only from the `CORE_TIMELOCK` key. Agents must not run this. `cast send` does not enforce the script's address book, so check `owner()` first.

```bash
cast send "$DISPUTE_PANEL" "setArbitrator(address,bool)" "$ARBITRATOR_1" true \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --private-key "$PRIVATE_KEY"
```

Repeat for the second and third seats (`true`). A removal passes `false`. After three successful adds, `arbitratorCount` is at least 3 and `openDispute` can succeed. Dropping below 3 makes `openDispute` revert `panel not seated` again.

## Failure modes

| Revert | When |
| --- | --- |
| `OpsLive: mainnet forbidden` | Panel ops on chainid `1` |
| `OpsLive: Base Sepolia (84532) only` | Panel ops on any other chain, including Ethereum Sepolia and Anvil |
| `DeployEscrow: mainnet forbidden` | Escrow deploy on chainid `1` |
| `DeployEscrow: Base Sepolia (84532) only; ...` | Escrow deploy on any other chain |
| `DeployEscrow: CORE_TIMELOCK unset` / `must not be deployer` | Escrow env |
| `DeployEscrow: DENYLIST unset` / `VAULT unset` / `DISPUTE_PANEL unset` | Escrow env missing or zero |
| `OpsPanel: DISPUTE_PANEL unset` / `ARBITRATOR unset` / `ARBITRATOR_1 unset` (and `_2`, `_3`) | Missing or zero panel-op env |
| `OpsLive: CORE_TIMELOCK unset` | Panel op missing the timelock env |
| `OpsPanel: DISPUTE_PANEL is not the live Base Sepolia DisputePanel` | Env panel is not the live address |
| `OpsLive: CORE_TIMELOCK is not the live owner` | Env timelock is not the book address |
| `OpsPanel: DisputePanel.owner is not CORE_TIMELOCK` | On-chain owner moved |
| `OpsPanel: zero arbitrator` / `duplicate arbitrator` | Seat list |
| `OpsLive: PRIVATE_KEY is not the live owner; Spencer only` | Panel `--broadcast` with any other key |
| `OpsLive: owner unset` | Empty owner passed into the helper |
| `not owner` | `setArbitrator` from anyone except `owner()` |
| `zero arbitrator` | Panel rejects `address(0)` if a call reaches it |
| `panel not seated` | `openDispute` while `arbitratorCount < 3` |
| `FundingBeforeGovernance` | `createEscrow` before `acceptOwnership` |

## Checklist

- [x] Gate B seated (`arbitratorCount` is 3; seat txs in block 47299643)
- [x] Escrow deployed (`0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c`, block 47299930)
- [x] `CORE_TIMELOCK` `acceptOwnership` on the escrow (block 47300275; `pendingOwner` is zero)
- [x] Real escrow address and txs are in `deployments/base-sepolia.json` and `contracts/README.md`
- [x] Agents do not `--broadcast` and do not touch mainnet
