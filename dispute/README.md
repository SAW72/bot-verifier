# Dispute Resolution

## Purpose
A lightweight on-chain court for bot audits, flags, and insurance claims.

## When It Triggers
- Two auditors disagree on a fingerprint
- A bot owner claims a false positive
- An insurance claim is contested
- A denylist entry is challenged

## Panel
- 3 independent arbitrators, staked
- Selected by reputation-weighted random draw
- Majority decision is binding after timelock

## Process
1. Dispute filed with evidence hash
2. Panel assigned automatically
3. Each arbitrator submits a vote + reasoning hash
4. Majority wins; minority can publish dissent
5. Decision is final and on-chain
