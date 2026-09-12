# BVT tokenomics (one page)

**Bot Verifier Token (BVT)** is the ERC-20 that prices audits, bonds auditors, and governs protocol parameters. There is **no premine for sale**, no VC allocation, and no public-sale mint.

## Who can mint

Supply starts at **0**. Only two contracts hold `MINTER_ROLE`:

| Path | Caller | What happens |
| --- | --- | --- |
| **Usage / earn** | `BVTFeeRouter` (`EARNER_ROLE`) | `awardUsage` or `settleAudit` mints **unlocked** BVT to the worker (auditor, scenario contributor). |
| **Operator bootstrap** | `BVTStaking` (`BOOTSTRAP_ROLE`) | `bootstrapOperator` mints BVT and **immediately locks** it as stake. Not transferable until unstake + 48h cooldown. |

Nobody else can mint. The constructor does not mint. There is no `buy`, `presale`, or ICO.

Liquid BVT that bots use to pay fees comes from earn mints (and later secondary transfer). Bootstrap never creates a sale allocation.

## Staking and slash

Auditors lock BVT (`stake`) or are bootstrapped. **Active** iff `stake >= minStake` (default **10,000 BVT**) and not banned.

| Parameter | Default | Who changes it |
| --- | --- | --- |
| `minStake` | 10,000 BVT | Governance (timelock) |
| `unstakeCooldown` | **48 hours** (dispute window) | Governance |
| Fake hash slash | **100%** + ban | `SLASHER_ROLE` executes; bps via governance |
| Rigged scores slash | **100%** + ban | same |
| Buried incidents slash | **50%** | same |

**Slash roles:** `SLASHER_ROLE` on `BVTStaking`. Deploy grants it to the **timelock** (governed slashes) and the **deployer** on testnet so it can later be moved to `DisputePanel`. Governance can `unban`.

Slashed tokens: **30% to the challenger** (if set), **remainder to `insuranceSink`**. No challenger → 100% to insurance.

## Fee payment and sinks

Bots pay unlocked BVT to `BVTFeeRouter` for **registration**, **audit**, and **vault access** (tiered). Existing `Vault` / `Denylist` do **not** call this yet — they can later `requirePaid(botId, kind)` via `IBVTFeeGate`.

| Sink | Default split | Address |
| --- | --- | --- |
| Auditor (or treasury if no auditor on the payment) | **70%** | named auditor or `treasury` |
| Insurance | **20%** | `insuranceSink` (BVT-denominated; today’s `InsuranceFund` is ETH-native — wire an adapter later) |
| Treasury | **10%** | `treasury` (governance) |

Default fees: register **100**, audit **250**, vault Chat/Data/Financial/Critical **50 / 100 / 250 / 500** BVT. After an audit fee is paid, `settleAudit` mints the usage reward (default **50 BVT**) to the active auditor.

## Governance + timelock

Voting power = **staked BVT** (lockup). Proposal threshold = `minStake`. Voting period **5 days**. Quorum **10%** of `totalStaked` at propose. Pass = more for than against.

Passed proposals **queue** in `BVTTimelock` (default delay **48 hours**, min 1h / max 30d). Execute only after `eta`. Guardian/admin/governor can **cancel** during the delay. Parameter changes (`minStake`, fees, splits, sinks, slash bps, governor params, delay) go through this path. The same timelock can later own `Denylist` / `Vault` for denylist upgrades and tier changes without rewriting those contracts now.

## What this is not

Not a fundraising token. Not a liquidity-mining program. Not a claim on ETH in `InsuranceFund`. Additive to the go-live stack: `script/Deploy.s.sol` (core) stays independent of `script/DeployBVT.s.sol`.
