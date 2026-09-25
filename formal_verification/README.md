# Formal Verification Layer

Security-critical contracts need mathematical proof, not just tests.

## Why
The denylist and vault contracts control bans, access grants, and burns. Vault burn is irreversible. Denylist active membership can be cleared by the owner; listing history cannot. A bug in matching could let a dangerous bot slip through, or a bug in history could hide that it was ever listed.

## Approach
- Use a formal verification tool (Certora, Slither, or equivalent)
- Specify invariants the contracts must always hold
- Prove the invariants hold for all possible states
- Run verification in CI on every contract change

## Invariants to Prove
1. Clearing an active denylist row does not erase `timesListed` or `everListed` (history survives removal)
2. A burned bot ID can never be re-registered (burn is final)
3. `PromptBlock` is a hard block. Vault `register` and escrow `_verifyBot` reject every `MatchLevel` other than `None`, including prompt-hash matches. A previous draft of this list said prompt matches must not auto-reject. That contradicted the fail-closed register and verify paths, so it is retired.
4. Vault access grants require a valid, non-expired attestation
5. No single key can upgrade the denylist or vault without the governance threshold

## Files
- `invariants.md` — full list of invariants
- `verification_spec.md` — how to run the verification suite
- `ci_verification.yml` — GitHub Actions workflow for automated checks