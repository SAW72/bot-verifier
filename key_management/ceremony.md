# Key Ceremony

How the hub, denylist, and vault keys are generated and distributed.

## Goal
No single person can unilaterally compromise the system.

## Steps
1. **Generate**: Run keygen in an air-gapped machine. Produce a 2-of-3 multisig (or threshold scheme) for the Denylist owner, Vault owner, and Liability owner.
2. **Distribute**: Each signer receives one shard on a hardware wallet. Shards never travel together.
3. **Verify**: All signers confirm the same public addresses on-chain.
4. **Rotate**: Every 90 days, or on any signer compromise, run a new ceremony. Old keys are deprecated via the timelock in `blockchain_bot/governance`.
5. **Emergency freeze**: If a signer is lost or malicious, the remaining signers can trigger the timelock to pause upgrades and new registrations until a new ceremony completes.

## Rules
- Ceremony is recorded on-chain (event log) for auditability.
- No key shard is ever stored in plaintext on a networked machine.
- The denylist owner key is the most sensitive — losing it means no new denylist entries, but existing entries remain.
