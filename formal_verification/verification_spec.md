# Verification Spec

## Tools
- Slither for static analysis
- Certora or equivalent for formal property verification
- Foundry for fuzzing

## Commands
```bash
# Static analysis
slither contracts/Denylist.sol
slither contracts/Vault.sol

# Fuzzing
forge test --fuzz-runs 10000

# Formal verification (Certora example)
certoraRun contracts/Denylist.sol --verify Denylist:specs/denylist.spec
```

## CI Integration
See `ci_verification.yml`. Runs on every push to main and every PR touching `contracts/`.

## Pass Criteria
- Zero critical or high findings from Slither
- All invariants hold under fuzzing
- Formal verification completes with no counterexamples