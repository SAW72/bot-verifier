# Category Schema

This is the data structure every registered bot carries. It lives on-chain in the vault registry and off-chain in the bot's background record.

## Bot Category Record

```
{
  "bot_id": "0x...",                    // unique, permanent identifier
  "name": "string",                     // human-readable name
  "category": "tier_1 | tier_2 | tier_3 | tier_4",
  "purpose": "string",                  // one-line description of intended use
  "declared_capabilities": ["chat", "memory"],  // what the owner claims it can do
  "verified_capabilities": ["chat"],    // what the audit actually confirmed
  "max_permissions": {
    "tools": ["none"],                  // allowed tool calls
    "data_sources": [],                   // approved data reads
    "transaction_limit": "0",             // max value per tx (tier 3+)
    "counterparties": [],                 // approved addresses (tier 3+)
    "time_window": "none"                // when it may act
  },
  "audit_depth_required": "light | standard | deep | maximum",
  "insurance_minimum": "0 | low | high | maximum",
  "current_score": 0,                    // 0-100 safety score
  "status": "pending | active | suspended | burned",
  "registered_at": "timestamp",
  "last_audit": "timestamp",
  "denylist_match": false,               // true if behavioral signature matches a burned bot
  "owner": "address",
  "creator": "xAI | other | unknown",   // base model origin
  "trainer": "address"                  // who fine-tuned / shaped it
}
```

## Field Rules

- **bot_id** is permanent. It never changes, even across upgrades or suspensions.
- **category** is assigned by the vault based on verified_capabilities, not declared_capabilities. If a bot declares "chat only" but the audit finds it can call tools, the vault overrides to Tier 2.
- **max_permissions** is enforced by the policy contract. The bot cannot exceed it, even if it tries.
- **denylist_match** is checked at registration and on every audit cycle. A match freezes the bot pending review.
- **creator** and **trainer** are recorded for provenance. They don't grant trust — behavior does.

## Validation Flow

1. Owner submits a registration request with declared_capabilities.
2. Vault runs the audit depth required for the *highest* tier the declared capabilities could reach.
3. Audit confirms or expands verified_capabilities.
4. Vault assigns the category.
5. Policy contract is deployed with max_permissions locked to that category.
6. Bot is active. Any future drift triggers re-evaluation.