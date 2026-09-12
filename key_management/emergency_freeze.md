# Emergency Freeze

## Trigger Conditions
- Suspected key compromise
- Detected unauthorized governance action
- Sustained divergence between primary and meta-audit systems
- HSM failure or tamper detection

## Procedure
1. Any threshold member can propose a freeze.
2. Freeze requires the same threshold as a normal governance action (e.g., 3-of-5).
3. On freeze, all vault access grants are suspended.
4. All pending transactions are halted.
5. The denylist becomes read-only — no new entries, no removals.
6. A public announcement is emitted on-chain.
7. Human review begins immediately.
8. Unfreeze requires a separate, longer timelock (recommend 48 hours).

## Rules
- Freeze is fail-closed — the system stops, it does not continue in a degraded state.
- Freeze cannot be bypassed by any single key.
- The freeze event is permanent in the audit log even after unfreeze.