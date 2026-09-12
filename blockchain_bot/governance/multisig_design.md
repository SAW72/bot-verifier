# Multi-Sig Design

## Goal
Require multiple independent signers to approve any policy upgrade. No single key controls the leash.

## Recommended default
**2-of-3 multisig** for early builds. Move to 3-of-5 once the auditor network grows.

## Signers (suggested split)
1. **Owner / builder** (Spencer) — knows the product intent.
2. **Independent auditor** — runs the verifier, has no financial stake in loosening rules.
3. **Community or DAO rep** — represents users who depend on the bot.

## Rules
- Threshold must be >50% of signers.
- Signers must be distinct entities (different wallets, ideally different hardware).
- A signer who is also the bot's operator is a conflict — avoid it.
- Rotation: any signer can be replaced by a proposal that itself passes the current threshold.

## Failure modes to watch
- All signers collude → still possible, but harder than one key.
- One signer goes dark → threshold becomes unreachable. Mitigate with a backup signer and a documented recovery path.
- Key compromise → rotate immediately via the remaining honest signers.

## Integration with policy contract
The policy contract's `upgradeTo(newImplementation)` (or equivalent) is gated behind the multisig. The multisig calls it only after threshold signatures are collected.

See `example_timelock.sol` for a combined multisig + timelock stub.