# Bank Adoption Layer

This layer sketches how the verifier could become an **experimental, optional institutional signal**. It is **not** a trust standard banks can require, **not** a certification, and **not** a safe harbor.

Stamps do **not** create a lawsuit waiver. Institutions that want allocation of risk need **separate written contracts**. See [DISCLAIMER.md](../DISCLAIMER.md).

## The Flywheel

1. Institutions do not have to build the verifier.
2. An institution *may* choose to consult the stamp as one optional input — never as a mandated certification.
3. Bot builders may register to obtain that experimental signal.
4. More registrations can make the signal more useful; that does not make it required infrastructure.
5. Treat this as a product experiment, not a promise that the system "becomes infrastructure."

## What an Institution Gets

- A single API call: `isBotTrusted(botId)` (heuristic; not a trust warranty)
- An experimental attestation record that a bot passed the configured audit depth for its tier (TEE may still be a stub)
- A denylist check that the bot is not burned or flagged (may be wrong, gamed, or stale)
- A portable fingerprint that is designed to work across chains
- An **experimental claims backstop** (fee-funded pool) — **NOT insurance**, and **not** a promise that anyone will be paid

## What a Bot Builder Gets

- A clear path to bank access
- A tier assignment based on what the bot actually does
- A public reputation that follows it everywhere
- A way to prove it is not the same as a previously destroyed dangerous bot

## Anchor Tenants

The first banks to adopt will be the ones with the most to lose:
- Crypto-native banks
- Neobanks already burned by bad bots
- Payment processors handling agentic transactions

Big banks follow when the network effect tips.

## Custom Rules

Banks can set their own thresholds on top of the base standard:
- Higher minimum audit score
- Additional denylist entries
- Stricter tier requirements
- Custom experimental claims-backstop minimums (**not insurance**)

This must not fragment the standard. The base attestation is universal. Bank-specific rules are additive overlays.
