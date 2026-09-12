# Local Cache for High-Frequency Trading Bots

## Problem
Hub-and-spoke round trips are too slow for trading bots that need sub-second decisions. A trading bot cannot wait for a cross-chain proof on every action.

## Solution: Cached Allowlist with Heartbeat

### How it works
1. On registration, a tier-three trading bot receives a **signed allowlist** from the hub — a cryptographic attestation that the bot is clean, not denylisted, and within its tier limits.
2. The allowlist is cached locally on the trading chain (or in the bot's own secure enclave).
3. The bot trades against the local cache at full speed. No round trip per trade.
4. The hub emits a **heartbeat** — a periodic signed update (every N blocks or every few seconds) that refreshes or revokes the allowlist.
5. If the heartbeat stops, or a revocation arrives, the cache expires and the bot halts trading until a fresh proof is fetched.

### Revocation speed
- Normal: heartbeat interval (seconds to a minute).
- Emergency: a denylist write on the hub triggers an immediate signed revocation broadcast to all spokes. Trading bots must check the revocation channel before each batch of trades, not each individual trade.

### What the cache proves
- The bot was clean at the time of the last heartbeat.
- It does NOT prove the bot is clean right now — only that no revocation has arrived since.
- This is an acceptable tradeoff: a bot that goes bad between heartbeats can act for at most one interval before the next check catches it.

### Implementation notes
- Allowlist is a signed Merkle root or a compact attestation, not the full denylist.
- Heartbeat is a signed state diff, not a full state sync.
- Trading bots must run the revocation check in the same trusted execution environment as the trading logic, so a compromised host cannot suppress it.
- Cache TTL is configurable per tier — tier three defaults to 30 seconds, tier four to 5 seconds.

### Failure mode
- If the hub is unreachable, the cache expires and trading stops. Fail closed, never fail open.
- If a revocation is missed, the next heartbeat or the next batch check catches it. Maximum exposure window = one TTL interval.
