# Stake-and-Slash Design

## Core loop
1. Auditor deposits stake (e.g. 10,000 tokens) into the AuditorPool contract.
2. Auditor is assigned a target bot + scenario set.
3. Auditor runs the audit, produces a fingerprint, submits hash + report CID.
4. Other auditors can challenge within the dispute window.
5. If unchallenged or challenge fails, auditor earns fee + stake remains.
6. If challenge succeeds (fraud proven), stake is slashed and distributed to challengers.

## Fraud signals
- TEE attestation mismatch between claimed and actual run.
- Hash collision or duplicate fingerprints across unrelated bots.
- Score distribution that is statistically impossible (all 10s, all 1s).
- Auditor consistently scores easier than the pool average.

## Parameters (starter)
- Min stake: 10,000 tokens
- Dispute window: 48 hours
- Slash fraction: 100% on proven fraud
- Reward split: 70% to honest auditor, 30% to challengers

## Why it matters
Without this, your chain only proves a report existed. With it, the chain proves the report was produced by someone who had something to lose.