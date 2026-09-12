# Formal Verification Layer

Security-critical contracts need mathematical proof, not just tests.

## Why
The denylist and vault contracts control irreversible actions — permanent bans, access grants, burns. A bug in the burn function or graduated matching could let a dangerous bot slip through or lock out honest ones forever.

## Approach
- Use a formal verification tool (Certora, Slither, or equivalent)
- Specify invariants the contracts must always hold
- Prove the invariants hold for all possible states
- Run verification in CI on every contract change

## Invariants to Prove
1. A denylisted fingerprint can never be removed (irreversibility)
2. A burned bot ID can never be re-registered (burn is final)
3. Graduated matching never auto-rejects on prompt-hash match alone (no false positive wall)
4. Vault access grants require a valid, non-expired attestation
5. No single key can upgrade the denylist or vault without the governance threshold

## Files
- `invariants.md` — full list of invariants
- `verification_spec.md` — how to run the verification suite
- `ci_verification.yml` — GitHub Actions workflow for automated checks