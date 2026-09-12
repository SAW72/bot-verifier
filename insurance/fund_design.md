# Insurance Fund Design

## Contract Sketch
- `InsuranceFund.sol` holds the pool
- `deposit()` accepts fees from vault and action logs
- `claim(incidentId, evidenceHash)` opens a claim
- `resolve(claimId, approved)` releases funds after governance approval
- Events: `ClaimOpened`, `ClaimResolved`, `PayoutSent`

## Risk Model
- Fund is not infinite. Fees must cover expected losses.
- High-risk bots pay higher registration fees.
- Repeated incidents raise a bot's risk tier and fee.

## Integration
- Reads from `background/incident_log_schema.md`
- Requires `consensus/` approval before payout
- Writes to `vault/` reputation ledger on payout
