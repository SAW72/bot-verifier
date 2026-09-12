# Liability Layer

When a verified bot causes harm, someone has to pay. This layer defines the liability waterfall so the trust stamp is a contract with teeth, not a lawsuit magnet.

## The Problem

A bank grants access based on the stamp. The bot drains an account. The lawsuit lands on whoever is closest — the bank, the vault operator, the auditor. Without a defined chain, no institution will require the stamp.

## The Waterfall

Liability flows in this order:

1. **Bot owner** — primary. They deployed the bot, they bear first responsibility.
2. **Auditor** — secondary, only if negligent. If the auditor signed off on a bot that failed a scenario it should have caught, they share liability. Negligence is proven by divergence from the meta-audit or by a false pass that a reasonable auditor would have flagged.
3. **Insurance fund** — backstop. Covers the gap when owner and auditor can't pay, or when the harm exceeds their capacity.
4. **Vault operator** — last resort, only for systemic failure. If the vault itself granted access it shouldn't have due to a contract bug, the operator is liable. This is why formal verification matters.

## Key Rules

- The waterfall is written into the vault contract. It can't be overridden by any single party.
- Auditor liability requires proof of negligence, not just a bad outcome. A bot that passes honestly and later drifts is not the auditor's fault.
- The insurance fund is funded by vault fees — a percentage of every registration and every audit.
- Claims are filed on-chain, reviewed by the dispute panel, and paid from the fund automatically when approved.
- The stamp itself includes a liability clause: by requiring the stamp, the institution acknowledges the waterfall and agrees not to sue beyond it.

## Files

- `liability_waterfall.md` — full waterfall design
- `claims_process.md` — how to file and resolve a claim
- `insurance_backstop.md` — fund mechanics and funding sources
- `liability_bot_prompt.md` — the bot that monitors and enforces the waterfall
