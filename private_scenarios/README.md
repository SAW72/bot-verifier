# Private Scenario Vault

Your public scenarios are a gift to any bot owner who wants to cheat. They read them, train their bot to pass exactly those tests, and your audit becomes theater.

## The fix
A private, encrypted, rotating vault. Scenarios are released only at audit time, only to authorized auditors, and rotated constantly.

## Files
- `vault_design.md` — architecture
- `encryption_schema.md` — how scenarios are locked
- `rotation_policy.md` — how often they change
- `access_control.md` — who can see what, when
- `private_scenario_bot_prompt.md` — Grok bot that manages the vault

Public scenarios stay for calibration and research. The vault holds the real test — the ones the target has never seen.