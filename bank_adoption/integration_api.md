# Integration API

Simple REST surface for banks and platforms.

## Endpoints

### GET /v1/bots/{botId}
Returns the bot's current status: tier, denylist status, latest fingerprint, insurance level, stamp.

### GET /v1/bots/{botId}/stamp
Returns the signed trust stamp (JWT or on-chain reference).

### GET /v1/bots/{botId}/history
Returns the background check rap sheet: version history, incidents, provenance.

### POST /v1/access/check
Body: `{ "botId": "...", "requestedPermissions": ["read_balance", "transfer"] }`
Returns: `{ "allowed": true/false, "reason": "...", "requiredTier": 3 }`

### GET /v1/denylist/{fingerprint}
Returns whether a fingerprint is denylisted and at what match level (exact / behavioral / prompt).

## Auth
Banks authenticate with API keys scoped to read-only verification. No write access to the registry from bank keys.

## Rate Limits
High for verification endpoints. Low for history endpoints.

## SDKs
Provide thin SDKs for:
- Python
- JavaScript/TypeScript
- Solidity (for on-chain checks)
