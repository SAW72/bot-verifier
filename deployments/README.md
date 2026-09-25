# Deployments

Committed address book for networks this repo is allowed to deploy. **Base Sepolia (chain id 84532) only.** Mainnet is refused by every deploy script.

## `base-sepolia.json`

Core contract addresses are filled in. `BotAttestationEscrow` and the BVT slots stay `null` with empty `deployTx` until those deploys. Do not invent addresses. Do not commit `PRIVATE_KEY`, RPC credentials, or API keys.

JSON has no comments. Field meanings:

| Field | Meaning |
| --- | --- |
| `schemaVersion` | `1`. Bump only if the shape changes. |
| `chainId` | Must stay `84532` (Base Sepolia). |
| `network` | `base-sepolia`. |
| `status` | `live` once core contracts are on Base Sepolia. Escrow and BVT can still be null. |
| `notes` | Free text. Keep the warning that agents do not `--broadcast`. |
| `coreTimelock` | `CORE_TIMELOCK` address (timelock or multisig, not the deployer), or `null`. |
| `bvtGuardian` | `BVT_GUARDIAN` address, or `null`. |
| `<Contract>.address` | Deployed contract address, or `null`. Live `Denylist` and `Vault` are the current pair. |
| `<Contract>.deployTx` | Broadcast transaction hash that created the contract, or `""`. |
| `<Contract>.transferOwnershipTx` | Optional. Tx that called `transferOwnership`. This is not `acceptOwnership`. |
| `<Contract>.acceptOwnership` | Optional. `pending` until `coreTimelock` accepts. |
| `superseded` | Previous Denylist and Vault. Each keeps `address`, `deployTx`, `supersededBy`, and why it was replaced. These are not the live slots. |

Contract slots, in deploy order:

1. `Denylist`, `Vault`, `Liability`, `InsuranceFund`, `DisputePanel` — `script/Deploy.s.sol`
2. `BotAttestationEscrow` — `script/DeployBotAttestationEscrow.s.sol`
3. `BVT`, `BVTStaking`, `BVTFeeRouter`, `BVTTimelock`, `BVTGovernor` — optional `script/DeployBVT.s.sol`

`Denylist`, `Vault`, and `BotAttestationEscrow` use OpenZeppelin **Ownable2Step**. After `transferOwnership(CORE_TIMELOCK)` the deployer is still owner until `coreTimelock` calls `acceptOwnership`. On the current book that accept is still pending on **both** the live Denylist and the live Vault: `owner` is the deploy sender `0x5D467FA00eC0E92044f779e495a17db66c5964aa` and `pendingOwner` is `coreTimelock`. Gate A is not done for that pair. The previous Denylist and Vault are under `superseded` and stay on chain. The superseded Denylist `owner` is `coreTimelock` and its `pendingOwner` is zero; it was not touched by the PR #11 redeploy. The superseded Vault still points at that old Denylist. Listing migration replay of `Listed` / `Unlisted` from the old Denylist was empty (0 Exact / 0 Signature / 0 Prompt). Escrow is not deployed.

`DisputePanel` ownership moves immediately via `setOwner`. `openDispute` reverts with `panel not seated` until that owner has called `setArbitrator` for three addresses (`arbitratorCount >= 3`).

Spencer fills this file. Agents do not `--broadcast`.
