# Claim relayer (Base Sepolia scaffold)

Gas and ops stub for bot-verifier claim flow. Default mode is **fixtures / dry-run**. This process does not sign, does not dial RPC, and does not submit transactions.

Public funding wallet (address only): `0x9D1b3E1400D2632d435cB7C0fC131C4f42B31861`.

`BotAttestationEscrow` and BVT are still null in `deployments/base-sepolia.json`. Leave `ESCROW_ADDRESS` empty until that book is filled. Health then reports `escrowBooked: false`, and `/v1/claims/quote` plus `/v1/claims` stay fixture-only.

## HARD STOP

- **Base Sepolia only** (chain id **84532**). Ethereum mainnet (`1`), Base mainnet (`8453`), and every other chain are refused.
- **No live submit** in this build, even if `RELAYER_PRIVATE_KEY` is set and `LIVE_SUBMIT=1`. The effective gate stays off until **Escrow is booked and Spencer authorizes the run** (`SPENCER_RUN_AUTH=1`). A later change has to add the send path on purpose.
- **Agents do not `--broadcast`.** Do not add forge broadcast scripts. Do not deploy Escrow or BVT from here.
- **Never invent balances.** Quote amounts are echoed from the client. This service does not read wallet balances.
- **Never commit secrets or private keys.** `RELAYER_PRIVATE_KEY` is a runtime environment variable only. The code does not read it and does not write it to disk or to the JSONL log.

## Run locally

```bash
cd claim-relayer
cp .env.example .env
# edit .env if you want; empty defaults are enough for fixtures
set -a
source .env
set +a
npm start
```

Listens on `127.0.0.1:8790` unless `HOST` or Render's `PORT` is set. Render must bind `0.0.0.0`.

```bash
npm test
```

Tests use Node's built-in runner. They do not touch the network.

## Fixture mode

`LIVE_SUBMIT` defaults to `0`. Quote and claim routes return labeled fixtures.

`GET /health` and `GET /v1/health` (HTTP 200 even when the kill switch is on):

```json
{
  "ok": true,
  "chainId": 84532,
  "network": "base-sepolia",
  "killSwitch": false,
  "mode": "fixture",
  "stub": true,
  "fixture": true,
  "escrowBooked": false,
  "escrowAddress": null,
  "relayerAddress": "0x9D1b3E1400D2632d435cB7C0fC131C4f42B31861",
  "liveSubmit": false,
  "liveSubmitRequested": false,
  "liveSubmitBlockers": ["scaffold_never_broadcasts", "escrow_not_booked", "spencer_run_auth_required", "live_submit_off"]
}
```

`liveSubmit` is always `false` in this scaffold. No private key is included.

## Wallet UX API (provisional)

Stable shapes for parallel Wallet UX work. Extra fields below are part of this scaffold's contract.

### `POST /v1/claims/quote`

Request:

```json
{ "payer": "0x1111111111111111111111111111111111111111", "payee": "0x2222222222222222222222222222222222222222", "amountWei": "1000", "claimId": "claim-1" }
```

`amountWei` and `claimId` are optional. `amountWei` is a base-10 integer string (echoed, not a balance). If `claimId` is omitted the service mints `fixture-` plus 16 hex chars. Optional `chainId` must be `84532`.

Response:

```json
{
  "claimId": "claim-1",
  "payer": "0x1111111111111111111111111111111111111111",
  "payee": "0x2222222222222222222222222222222222222222",
  "amountWei": "1000",
  "fixture": true,
  "expiresAt": "2026-09-25T20:00:00.000Z",
  "chainId": 84532,
  "mode": "fixture",
  "escrowBooked": false,
  "relayerAddress": "0x9D1b3E1400D2632d435cB7C0fC131C4f42B31861",
  "relayerNonce": "0"
}
```

`expiresAt` is ISO-8601 UTC. `amountWei` is omitted when the request omitted it. `relayerNonce` is an in-memory reservation for that `claimId` (same id refreshes the same nonce until expiry).

### `POST /v1/claims`

Request `{ "claimId": "claim-1" }`. Optional `payer`, `payee`, `amountWei`, `chainId`.

Fixture response (live submit off, which is always the case here):

```json
{ "ok": true, "mode": "fixture", "claimId": "claim-1", "txHash": null, "reason": "live_submit_blocked" }
```

A client that sets `live: true`, `liveSubmit: true`, or `mode: "live"` gets **409**:

```json
{
  "ok": false,
  "error": "live_submit_blocked",
  "reason": "awaiting_escrow_booking_and_spencer_run_auth",
  "mode": "fixture",
  "txHash": null
}
```

## Error codes

| HTTP | `error` | When |
| --- | --- | --- |
| 503 | `kill_switch` | Kill switch is on. Quote and claim are refused. Health stays 200. |
| 409 | `live_submit_blocked` | Client asked for a live transaction. |
| 400 | `mainnet_refused` | `chainId` is `1` or `8453`. |
| 400 | `wrong_chain` | Any chain other than `84532`. |
| 400 | `invalid_address` | `payer` or `payee` is missing or not a 20-byte hex address. |
| 400 | `invalid_parties` | Payer and payee are the same address. |
| 400 | `invalid_amount` | `amountWei` is not a positive integer. |
| 400 | `invalid_claim_id` | Claim id missing on submit, or an unexpected shape. |
| 400 | `invalid_json` | Body is not a JSON object. |
| 401 | `unauthorized` | Admin route called with the wrong `ADMIN_SECRET`. |
| 404 | `not_found` | Unknown path. |

Startup with `CHAIN_ID` other than `84532` refuses to boot (`mainnet_refused` or `wrong_chain`). `RELAYER_KEY_FILE` / `RELAYER_PRIVATE_KEY_FILE` refuse to boot. Keys stay in the environment.

## Kill switch

`KILL_SWITCH=1` starts paused. `POST /v1/admin/pause` and `POST /v1/admin/unpause` require header `x-admin-secret` or `Authorization: Bearer` matching `ADMIN_SECRET`.

If `ADMIN_SECRET` is unset, those routes return HTTP 200 and do **not** change the switch:

```json
{ "ok": true, "noop": true, "killSwitch": false, "docs": "ADMIN_SECRET is unset. ..." }
```

## Nonce store and logs

Reservations live in memory for one process. Render must run **one web instance**. Do not turn on horizontal scaling. A restart clears reservations; this stub does not read a pending nonce from chain.

`CLAIM_LOG_PATH` is append-only JSONL (default `./data/claims.jsonl`). Records are allowlisted. Private keys, secrets, and nested objects are dropped. On Render the disk is ephemeral, so use `/tmp/...` and expect the file to vanish on restart.

## Claim calldata

Builder will lock the Escrow calldata ABI later and inject it at `todoEscrowCalldata()` in `claims.mjs`. The on-chain surface today is `createEscrow`, `release`, and `refund` on `contracts/BotAttestationEscrow.sol`. Wallet reads of the live Vault can use `contracts/interfaces/IVault.sol`. Do not encode or broadcast that calldata in this scaffold.

## Render

See `render.yaml` in this directory. It is a reference Blueprint, not registered at the repo root. One web service, one instance, `HOST=0.0.0.0`, `LIVE_SUBMIT=0`. Put `RELAYER_PRIVATE_KEY` in the dashboard as a secret. Do not bake it into the Blueprint.
