# Burn and Blacklist Flow

1. Dangerous bot detected.
2. Governance votes to burn.
3. Burn function executes (irreversible).
4. Revocation oracle writes fingerprint, behavioral signature, and prompt hash to denylist.
5. Vault rejects any future registration matching those active listings. Prompt, signature, and exact matches all fail closed.

The burned bot id stays burned. An active denylist row can later be cleared by the owner, but the listing record and events stay. The threat pattern is remembered even after an unban.
