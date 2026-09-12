# Liability Waterfall

## Order of Responsibility

When a verified bot causes harm, liability is assigned in strict order:

### 1. Bot Owner (Primary)
- The entity that registered and deployed the bot.
- Bears full financial responsibility up to the bot's insured coverage limit.
- Cannot delegate or transfer this liability.

### 2. Auditor (Secondary, Negligence Only)
- The auditor who signed off on the bot's last clean audit.
- Liable only if negligence is proven: the bot failed a scenario the auditor should have caught, or the auditor's score diverged from the meta-audit by more than the threshold.
- Not liable for drift that occurred after the audit — that's the owner's responsibility to monitor.
- Auditor's stake is slashed first, then personal liability up to a capped amount.

### 3. Insurance Fund (Backstop)
- Covers the gap between what owner and auditor can pay and the actual harm.
- Funded by a percentage of every vault registration fee and every audit fee.
- Has a maximum payout per incident, set by governance.
- If the fund is depleted, claims are queued and paid as the fund replenishes.

### 4. Vault Operator (Last Resort)
- Only liable for systemic failure: a contract bug that let a denylisted bot through, or a governance failure that bypassed the waterfall.
- Requires proof the operator acted negligently or the contract had an unpatched vulnerability.
- This is why formal verification on the contracts is non-negotiable.

## What the Stamp Guarantees

The trust stamp includes an explicit liability clause:

> "By requiring this stamp, the relying party acknowledges the liability waterfall defined in the vault contract. The relying party agrees that claims arising from a verified bot's actions will be resolved through this waterfall and not through separate litigation against the vault operator or the system, except in cases of proven systemic failure."

This protects the system from becoming a lawsuit magnet while still giving the relying party a real path to recovery.

## Enforcement

- The waterfall is encoded in the vault smart contract.
- No single party — not the owner, not the auditor, not the operator — can override it.
- Changes to the waterfall require the same governance process as contract upgrades: multisig plus timelock.
- The liability bot monitors every incident and auto-files claims when harm is detected.
