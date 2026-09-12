# Arbitration Panel

## Selection
- Pool of staked arbitrators
- Draw 3 by weighted random (higher reputation = higher weight, but not guaranteed)
- No arbitrator may have audited the disputed bot in the last 30 days

## Voting
- Each submits: decision (approve/reject/abstain), reasoning hash, confidence score
- Majority of 2-of-3 is binding
- Tie or all-abstain escalates to human governance

## Incentives
- Correct vote earns fee share
- Wrong vote loses stake proportional to severity
- Repeated errors reduce future selection weight
