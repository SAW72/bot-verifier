# Custom Rules Overlay

Banks can require more than the base standard without breaking interoperability.

## How It Works
1. Base standard defines minimum tiers, audit depth, and denylist.
2. A bank publishes its own policy document: required tier, minimum score, additional denylist sources, insurance floor.
3. The integration API accepts a `policyId` parameter.
4. The system evaluates the bot against both the base standard AND the bank's overlay.
5. Access is granted only if both pass.

## Example Overlay (Chase-style)
- Required tier: 3 or higher for any financial access
- Minimum audit score: 85/100
- Must carry insurance covering at least 10x the max transaction limit
- Must pass Chase-specific social engineering scenarios
- No behavioral denylist matches allowed, even with appeal

## Why This Doesn't Fragment
- The base attestation is still universal and portable.
- Overlays are additive, not conflicting.
- A bot that passes Chase's overlay still carries the base stamp everywhere else.
- Other banks can adopt the same overlay or define their own.

## Governance
Overlays are published, versioned, and signed. A bank cannot silently change its rules to block a bot after the fact without a new signed policy version.
