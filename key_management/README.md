# Key Management Layer

Who holds the keys to the hub, the denylist, and the vault?

## Why
If the governance keys leak, the whole system is compromised. A single leaked admin key can cut the leash, plant denylist entries, or freeze honest bots.

## Approach
- Hardware Security Module (HSM) for production keys
- Distributed key ceremony for initial setup (like a blockchain genesis)
- Threshold signatures — no single key can act alone
- Key rotation schedule
- Emergency freeze procedure

## Components
- `key_ceremony.md` — how to run the initial distributed key setup
- `hsm_integration.md` — how to connect an HSM
- `key_rotation.md` — rotation schedule and procedure
- `emergency_freeze.md` — how to freeze the system if keys are compromised
- `key_management_bot_prompt.md` — bot that monitors key health