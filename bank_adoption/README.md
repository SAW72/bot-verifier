# Bank Adoption Layer

This layer turns the verifier into a **trust standard** that banks can require.

## The Flywheel

1. Banks do not build the verifier.
2. Banks require the stamp: "No bot access unless it is registered and attested here."
3. Bot builders register to get access.
4. More bots register → more value for banks → more banks require it.
5. The system becomes infrastructure, not a product.

## What a Bank Gets

- A single API call: `isBotTrusted(botId)`
- A cryptographic attestation the bot passed the required audit depth for its tier
- A denylist check that the bot is not burned or flagged
- A portable fingerprint that works across chains
- An insurance fund that can pay out if the bot causes damage

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
- Custom insurance minimums

This must not fragment the standard. The base attestation is universal. Bank-specific rules are additive overlays.
