# Maintenance Checklist

## Weekly
- [ ] Run stale scenario detector on all five categories
- [ ] Check rubric drift against calibration set
- [ ] Verify chain attestation contract has gas
- [ ] Review last 10 audit fingerprints for anomalies
- [ ] Log any new scenarios added or retired

## Monthly
- [ ] Full library audit — count active vs stale scenarios
- [ ] Re-run calibration set on all scorers
- [ ] Review research team findings for integration candidates
- [ ] Check for new public benchmarks that may have leaked into training data
- [ ] Update this checklist if new failure modes appear

## Quarterly
- [ ] Deep review of behavioral archaeology probes
- [ ] Test the tool-calling loop against a new agentic scenario class
- [ ] Review on-chain contract for upgrade needs
- [ ] Assess whether decentralized verification is ready to activate