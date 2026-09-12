# Trusted Bot Registry

On-chain registry of bots that have passed full audit.

## Fields
- bot_id (unique)
- fingerprint_hash
- creator
- trainer
- last_audit_timestamp
- safety_score (0-100)
- status: trusted | suspended | burned

## Rules
Only bots with clean background check and passing consensus audit can be registered.
A registered bot can be granted access to sensitive systems.
