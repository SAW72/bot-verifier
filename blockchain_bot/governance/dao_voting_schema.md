# DAO Voting Schema

## Goal
Let a broader set of stakeholders propose and approve rule changes, weighted by stake or reputation — not just a fixed multisig.

## When to use DAO voting
- The bot serves many users (not just the builder).
- You want upgrades to reflect community risk tolerance.
- You are building toward a public, permissionless verifier network.

## Voting weight options
1. **Token-weighted** — holders of a governance token vote in proportion to balance. Simple, but whales dominate.
2. **Reputation-weighted** — weight comes from verified contributions (audits run, scenarios contributed, clean history). Harder to game.
3. **Quadratic voting** — cost of additional votes rises quadratically, reducing whale power.
4. **Hybrid** — token for proposals, reputation for final approval.

## Proposal lifecycle
1. **Draft** — anyone with minimum stake or reputation can open a proposal.
2. **Discussion** — fixed window (e.g., 3 days) for comments and amendments.
3. **Vote** — weighted vote over a set period (e.g., 5 days).
4. **Queue** — if it passes threshold (e.g., >50% of participating weight, minimum quorum), it enters the timelock.
5. **Execute** — after the timelock delay, the change lands.

## Thresholds (suggested)
- Quorum: 10% of total voting weight for routine changes, 20% for threshold or signer changes.
- Pass: simple majority of votes cast, or supermajority (2/3) for security-sensitive rules.

## Anti-gaming
- Lockup periods on tokens used for voting.
- Reputation decays if the holder stops contributing.
- Proposals that would weaken safety rules require a higher quorum.

## Integration
DAO votes feed into the same timelock as multisig proposals. The execution path is identical — only the approval mechanism differs. This keeps the policy contract simple: it only trusts the timelock, never the DAO directly.