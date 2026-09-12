# Claims Process

## Filing a Claim

Anyone harmed by a verified bot can file a claim on-chain:

1. Submit the claim to the vault contract with: bot ID, incident description, evidence (transaction hashes, logs, timestamps), and requested amount.
2. The claim enters a review queue.
3. The dispute panel — three staked arbitrators — reviews within a defined window (default 72 hours).
4. If approved, the claim is paid from the insurance fund automatically.
5. If denied, the claimant can appeal once to a larger panel.

## Evidence Requirements

- On-chain transaction records showing the bot's action.
- The bot's audit fingerprint at the time of the incident.
- Proof the bot was registered and active in the vault.
- A clear causal link between the bot's action and the harm.

## Resolution

- Approved claims are paid in order of filing.
- The fund pays up to its per-incident cap.
- If the fund is insufficient, the claim is partially paid and queued for the remainder.
- Denied claims can be appealed once. A second denial is final.

## Fraud Prevention

- False claims are penalized: the claimant's stake (if any) is slashed, and repeat false claimants are banned from filing.
- The liability bot cross-checks every claim against the action log before it reaches the panel.
- Arbitrators who approve fraudulent claims are themselves slashed.
