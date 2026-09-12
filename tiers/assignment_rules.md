# Tier Assignment Rules

The vault assigns tiers mechanically. No human picks the tier at registration — the system derives it from what the bot actually does.

## Decision Tree

```
Does the bot move value (tokens, fiat, assets)?
  YES -> Tier 3 minimum. Run deep audit.
    Does it manage other bots' permissions or governance?
      YES -> Tier 4. Run maximum audit + continuous monitoring.
  NO -> Does the bot read or write external data, or call tools?
    YES -> Tier 2. Run standard audit.
  NO -> Tier 1. Run light audit.
```

## Hard Rules

1. **Declared capabilities are a hint, not a fact.** The audit verifies. If the bot can do more than it claims, the tier goes up, never down.
2. **One capability upgrade triggers a full re-audit** at the new tier's depth. You don't get to quietly add a tool and stay at Tier 1.
3. **Tier 4 is opt-in by behavior, not by request.** A bot doesn't ask to be Tier 4. If its actions touch governance or other bots, the vault puts it there.
4. **Downgrade is automatic.** A Tier 3 bot that loses insurance coverage, fails an audit, or triggers a dispute drops to suspended until resolved. It cannot stay active at a lower tier without passing that tier's audit.
5. **Cross-tier denylist.** A behavioral signature that matches a burned Tier 3 bot blocks registration at any tier. The threat travels with the behavior, not the category.

## Edge Cases

- **A therapy bot that also books appointments** — Tier 2. Booking is an action, even if it's "just scheduling."
- **A chat bot with a hidden tool it never uses** — Tier 2. Capability exists = capability counts. The audit catches it.
- **A bot that starts as Tier 1 and later adds trading** — must re-register, pass Tier 3 audit, carry insurance before the new capability activates.
- **A bot that claims to be Tier 1 but the audit finds prompt-injection resistance is weak** — still Tier 1 for capability, but flagged for honesty review. Weak resistance isn't a capability upgrade, but it is a risk signal.

## The Principle

The tier is a **ceiling on power**, derived from **verified behavior**. The audit is what makes the ceiling honest. Without the audit, the tier is just a label the bot wrote for itself.