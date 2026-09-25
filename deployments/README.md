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
| `<Contract>.address` | Deployed contract address, or `null`. |
| `<Contract>.deployTx` | Broadcast transaction hash that created the contract, or `""`. |

Contract slots, in deploy order:

1. `Denylist`, `Vault`, `Liability`, `InsuranceFund`, `DisputePanel` — `script/Deploy.s.sol`
2. `BotAttestationEscrow` — `script/DeployBotAttestationEscrow.s.sol`
3. `BVT`, `BVTStaking`, `BVTFeeRouter`, `BVTTimelock`, `BVTGovernor` — optional `script/DeployBVT.s.sol`

`Denylist`, `Vault`, and `BotAttestationEscrow` use OpenZeppelin **Ownable2Step**. After `transferOwnership(CORE_TIMELOCK)` the deployer is still owner until `coreTimelock` calls `acceptOwnership`. On the live book, Denylist `owner` is `coreTimelock` and its `pendingOwner` is zero. Vault `pendingOwner` is `coreTimelock` and `acceptOwnership` has not been called, so the deploy sender is still Vault owner. Escrow is not deployed.

`DisputePanel` ownership moves immediately via `setOwner`. `openDispute` reverts with `panel not seated` until that owner has called `setArbitrator` for three addresses (`arbitratorCount >= 3`).

Spencer fills this file. Agents do not `--broadcast`.
