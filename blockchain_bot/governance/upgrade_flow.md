# Upgrade Flow

End-to-end path from a rule change idea to an executed policy update.

## Default path (recommended)
**2-of-3 multisig + 48-hour timelock**

1. **Propose** — A signer drafts the new policy (new limits, new approved counterparties, new escalation thresholds). Diff is published off-chain and hashed.
2. **Sign** — Two of three signers approve the proposal hash. The third can object.
3. **Queue** — Approved proposal is submitted to the timelock with a 48-hour delay. Event emitted: `ProposalQueued(id, newPolicyHash, executeAfter)`.
4. **Review window** — Anyone (auditors, users, the maintenance bot) can inspect the diff, run it against the scenario library, and file an objection.
5. **Cancel or execute** —
   - If an objection is upheld by a second signer, the proposal is cancelled: `ProposalCancelled(id, reason)`.
   - If the delay passes with no cancellation, the timelock calls the policy contract: `ProposalExecuted(id)`.
6. **Verify** — The verifier re-runs a calibration subset against the new policy to confirm behavior didn't silently degrade. Result is logged.

## Emergency path (security patch only)
- 24-hour delay instead of 48.
- Requires a documented reason on-chain.
- Still needs 2-of-3 signatures.
- Post-execution, a full audit is mandatory within 7 days.

## What never happens
- No instant upgrade by a single key.
- No upgrade without a public hash of the change.
- No upgrade without a review window.
- No upgrade that bypasses the timelock.

## Logging
Every step is an on-chain event. The background-check layer reads these events and includes governance history in the bot's rap sheet. A bot whose leash was tightened three times in a month tells a different story than one whose leash was never touched.