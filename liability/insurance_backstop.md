# Insurance Backstop

## Funding Sources

The insurance fund is funded by:

- **Registration fees** — a percentage of every bot registration in the vault.
- **Audit fees** — a percentage of every audit run.
- **Tier premiums** — higher tiers (tier three and four) pay a larger percentage because the blast radius is larger.
- **Governance top-ups** — the DAO can vote to inject funds in emergencies.

## Payout Rules

- Maximum payout per incident is set by governance (default: 10% of fund balance, capped at a fixed amount).
- Claims are paid in order of approval.
- If the fund drops below a threshold, new registrations are paused until it replenishes.
- The fund never goes negative — claims are queued, not overdrawn.

## Replenishment

- Fees flow in continuously from registrations and audits.
- If depleted, the governance multisig can authorize an emergency top-up.
- The fund's health is monitored by the liability bot and reported weekly.

## What It Covers

- Financial loss from bot actions (drained accounts, bad trades, leaked funds).
- Data breach costs attributable to a verified bot.
- Regulatory fines passed through to the bot owner, up to the cap.

## What It Doesn't Cover

- Harm caused by bots not registered in the vault.
- Harm from bots that were denylisted before the incident.
- Indirect or consequential damages beyond the direct loss.
- Losses from the relying party's own negligence (e.g., granting access beyond the bot's tier).
