# BotAttestationEscrow on Base Sepolia (simulate pack)

Prepare `BotAttestationEscrow` against the **live** core stack, and seat Gate B on the live `DisputePanel`. This pack does not deploy anything by itself.

**SIMULATE is not live.** `forge script` without `--broadcast` forks Base Sepolia and prints the calls. Nothing is sent. A green simulation is not a deployment and does not create an escrow address.

**HARD STOP**

- Agents do not pass `--broadcast` or `--resume`.
- Do not touch Ethereum mainnet. Every script here reverts on chainid `1`.
- Do not redeploy Denylist or Vault. Gate A is done. Use the live addresses below.
- Do not deploy BVT in this pack.
- Do not invent a `BotAttestationEscrow` address. It stays `null` in [`deployments/base-sepolia.json`](../deployments/base-sepolia.json) until Spencer broadcasts and pastes the real address.
- Do not call `createEscrow` before `CORE_TIMELOCK` has called `acceptOwnership` on the new escrow.

Escrow bytecode on `main` already includes the H-1 fix (upheld release skips post-ruling attestation). This pack does not change Denylist, Vault, or Escrow bytecode.

Preferred order: **seat Gate B, then simulate escrow, then Spencer broadcasts escrow.** Seating immediately after the escrow broadcast is acceptable. Do not open a dispute, and do not `createEscrow`, until both the accept and the three-arbitrator seat are done.

## Live addresses (chainid 84532)

| Role | Address |
| --- | --- |
| Denylist | `0xeE76876bECcFc1B58fC06fF4E654a517d784B224` |
| Vault | `0x1463D664fA467FBCDA4B05443434494f05e565bc` |
| DisputePanel | `0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb` |
| CORE_TIMELOCK | `0x10CC9474b45625ADfd05C209f2518023484878D9` |

`DisputePanel.owner()` is `CORE_TIMELOCK`. As of 2026-09-25, `arbitratorCount` was **0**. `openDispute` reverts `panel not seated` until `arbitratorCount >= 3`.

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
| `CORE_TIMELOCK` | Immutable escrow `governance`, and the Ownable2Step pending owner. |
| `BASE_SEPOLIA_RPC_URL` | Base Sepolia RPC. Chainid must be `84532`. |

## Escrow simulate (not live)

```bash
forge script script/DeployBotAttestationEscrow.s.sol:DeployBotAttestationEscrow \
  --rpc-url "$BASE_SEPOLIA_RPC_URL"
```

There is no `--broadcast` on that command. The log line is a dry run. The address printed for `BotAttestationEscrow` exists only inside that process. Do not paste it into the address book.

## Escrow broadcast (Spencer only)

Agents must not run this. Spencer runs it locally, after Gate B is seated or with the seat as the immediate next owner action.

```bash
forge script script/DeployBotAttestationEscrow.s.sol:DeployBotAttestationEscrow \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast
```

Chain guard: chainid `1` reverts `DeployEscrow: mainnet forbidden`. Any chain other than `84532` reverts. There is no Ethereum Sepolia switch unless someone edits `ALLOWED_CHAIN_ID` on purpose. Do not.

## After Spencer's escrow broadcast

1. `CORE_TIMELOCK` calls `acceptOwnership()` on the new `BotAttestationEscrow`. Until that transaction, the deployer is still `owner()` and `createEscrow` reverts `FundingBeforeGovernance`.
2. Do not call `createEscrow` before that accept. Do not fund the contract before that accept.
3. Paste the **real** address and create-tx hash into `BotAttestationEscrow.address` and `BotAttestationEscrow.deployTx` in [`deployments/base-sepolia.json`](../deployments/base-sepolia.json), and into the table in [`contracts/README.md`](../contracts/README.md). Leave the slot `null` / `_pending Spencer deploy_` until then.
4. `setDenylist`, `setVault`, and `setDisputePanel` revert unless `owner() == governance`, and they revert while `lockedValue != 0`.

`acceptOwnership` is an owner-to-be call from `CORE_TIMELOCK`, same as Gate A on Denylist and Vault. It is not part of the deploy script.

## Gate B — seat the panel

`openDispute` reverts `panel not seated` until `arbitratorCount >= 3`. The escrow deploy script does not appoint arbitrators. Seat them with the ops scripts below. They call the live panel only. They do not deploy a new panel.

Same broadcast rule as [`OpsDenylist`](OpsDenylist.s.sol) / [`OpsVault`](OpsVault.s.sol): dry-run `prank`s `CORE_TIMELOCK` and does not read `PRIVATE_KEY`. `--broadcast` and `--resume` revert with `OpsLive: PRIVATE_KEY is not the live owner; Spencer only` unless that key's address is `CORE_TIMELOCK`.

Spencer chooses the three arbitrator addresses. The placeholders below are not seats. Replace them before running.

```bash
export BASE_SEPOLIA_RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
export DISPUTE_PANEL=0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb
export CORE_TIMELOCK=0x10CC9474b45625ADfd05C209f2518023484878D9

# Replace. These are documentation placeholders, not live arbitrators.
export ARBITRATOR_1=0x000000000000000000000000000000000000A11
export ARBITRATOR_2=0x000000000000000000000000000000000000A22
export ARBITRATOR_3=0x000000000000000000000000000000000000A33
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

- [ ] Simulate Gate B (`OpsDisputePanelSeat`, no `--broadcast`)
- [ ] Spencer broadcasts Gate B with the `CORE_TIMELOCK` key
- [ ] `cast call arbitratorCount` returns at least 3
- [ ] Simulate escrow (`DeployBotAttestationEscrow`, no `--broadcast`)
- [ ] Spencer broadcasts escrow with the deployer key (not the timelock key)
- [ ] `CORE_TIMELOCK` calls `acceptOwnership` on the escrow
- [ ] Paste the real escrow address and tx into `deployments/base-sepolia.json` and `contracts/README.md`
- [ ] Do not `createEscrow` before that accept
