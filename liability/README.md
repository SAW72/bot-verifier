# Liability Layer

When a verified bot causes harm, recovery is uncertain. This layer describes an **experimental settlement / waterfall design**. It is **not** a lawsuit waiver, **not** insurance, and **not** a contract with teeth unless the parties sign **separate written agreements**.

A stamp does **not** mean anyone agreed not to sue. Institutions remain solely responsible for access decisions. See [DISCLAIMER.md](../DISCLAIMER.md).

## The Problem

An institution may consult a stamp and later suffer a loss. Without a separately negotiated allocation of risk, claims can land on whoever is closest — the institution, the vault operator, the auditor. The waterfall below is a **design sketch** for how a future contract *could* order recovery. It does not, by itself, bind anyone or make the stamp something an institution can safely "require."

## The Waterfall

Liability flows in this order:

1. **Bot owner** — primary. They deployed the bot, they bear first responsibility.
2. **Auditor** — secondary, only if negligent. If the auditor signed off on a bot that failed a scenario it should have caught, they share liability. Negligence is proven by divergence from the meta-audit or by a false pass that a reasonable auditor would have flagged.
3. **Experimental claims backstop** — **not insurance**. A fee-funded pool that *might* cover a gap if separately contracted, funded, and approved. Payment is not promised.
4. **Vault operator** — last resort, only for systemic failure. If the vault itself granted access it shouldn't have due to a contract bug, the operator is liable. This is why formal verification matters.

## Key Rules

- The waterfall is written into the vault contract. It can't be overridden by any single party.
- Auditor liability requires proof of negligence, not just a bad outcome. A bot that passes honestly and later drifts is not the auditor's fault.
- The claims backstop (if funded) would be funded by vault fees — a percentage of every registration and every audit. That pool is **not insurance**.
- Claims *could* be filed on-chain, reviewed by the dispute panel, and paid from the pool when a **separate contract** and the on-chain process both authorize it. Automatic payout is a design goal, not a guarantee.
- The stamp must **not** be marketed as containing a "do not sue beyond the waterfall" clause. Any limitation of claims requires a **separately executed contract**. Repo docs and stamp JSON are not that contract.

## Files

- `liability_waterfall.md` — full waterfall design
- `claims_process.md` — how to file and resolve a claim
- `insurance_backstop.md` — fund mechanics and funding sources
- `liability_bot_prompt.md` — the bot that monitors and enforces the waterfall
