# Timelock Pattern

## Goal
Give the world time to react before a rule change takes effect. A malicious or reckless upgrade cannot land instantly.

## How it works
1. A proposal is submitted (via multisig or DAO vote).
2. The change is queued in a timelock contract with a delay (default: **48 hours**).
3. During the delay, anyone can review the diff, run the new rules against the scenario library, and raise an objection.
4. After the delay, if no veto or cancellation occurred, the upgrade executes automatically.
5. A cancellation window (optional) lets the multisig abort before execution.

## Recommended delays
- **48 hours** — default for routine limit changes.
- **7 days** — for threshold changes, signer rotation, or emergency rule rewrites.
- **24 hours** — only for urgent security patches, and only with a documented reason logged on-chain.

## Why it pairs with multisig
Multisig prevents one person from acting alone. Timelock prevents the group from acting in secret or in a panic. Together they form a two-layer leash.

## Cancellation
Any current multisig signer can cancel a queued proposal before it executes. Cancellation itself should be logged and, for major changes, require a second signer.

## On-chain record
Every proposal, queue, delay, and execution is an event. Your background-check and incident-log layers read these events for free — the governance history becomes part of the bot's rap sheet.