# Key Rotation

## Schedule
- Governance keys: rotate every 90 days
- Hub signing keys: rotate every 30 days
- Emergency freeze keys: rotate every 180 days

## Procedure
1. Generate new key shard in HSM.
2. Add new shard to the threshold set.
3. Remove old shard after a grace period (recommend 7 days).
4. Record rotation on-chain.
5. Destroy old shard material.

## Emergency Rotation
If a key is suspected compromised:
1. Trigger emergency freeze immediately.
2. Revoke the compromised shard.
3. Run a partial ceremony for that shard only.
4. Resume operations after the new shard is verified.

## Rules
- Rotation never reduces the threshold below the minimum.
- Old keys are never reused after rotation.
- All rotations are public and auditable.