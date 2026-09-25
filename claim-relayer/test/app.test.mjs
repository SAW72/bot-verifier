import assert from "node:assert/strict";
import { once } from "node:events";
import { mkdtemp, readFile } from "node:fs/promises";
import http from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, it } from "node:test";
import { createClaimRelayer } from "../app.mjs";
import { createClaimLog } from "../claimLog.mjs";
import { loadConfig } from "../config.mjs";
import { createKillSwitch } from "../killSwitch.mjs";
import { createNonceStore } from "../nonceStore.mjs";

const PAYER = "0x1111111111111111111111111111111111111111";
const PAYEE = "0x2222222222222222222222222222222222222222";
const SECRET = "0x" + "cd".repeat(32);

describe("claim relayer HTTP", () => {
  it("serves fixture health, quote, and claim without leaking a key", async () => {
    const ctx = await boot();
    try {
      const health = await request(ctx.port, "GET", "/health");
      assert.equal(health.status, 200);
      assert.equal(health.json.ok, true);
      assert.equal(health.json.chainId, 84532);
      assert.equal(health.json.killSwitch, false);
      assert.equal(health.json.mode, "fixture");
      assert.equal(health.json.stub, true);
      assert.equal(health.json.fixture, true);
      assert.equal(health.json.escrowBooked, true);
      assert.equal(health.json.escrowSource, "address_book");
      assert.equal(health.json.escrowAddress, "0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c");
      assert.ok(health.json.liveSubmitBlockers.includes("spencer_run_auth_required"));
      assert.ok(health.json.liveSubmitBlockers.includes("scaffold_never_broadcasts"));
      assert.equal(health.json.relayerAddress, "0x9D1b3E1400D2632d435cB7C0fC131C4f42B31861");
      assert.equal(health.json.liveSubmit, false);
      assert.equal(JSON.stringify(health.json).includes(SECRET), false);
      assert.equal(JSON.stringify(health.json).toLowerCase().includes("private"), false);

      const quote = await request(ctx.port, "POST", "/v1/claims/quote", {
        payer: PAYER,
        payee: PAYEE,
        claimId: "claim-1",
        privateKey: SECRET,
      });
      assert.equal(quote.status, 200);
      assert.equal(quote.json.fixture, true);
      assert.equal(quote.json.claimId, "claim-1");
      assert.equal(quote.json.payer, PAYER);
      assert.equal(quote.json.payee, PAYEE);
      assert.equal(quote.json.chainId, 84532);
      assert.equal(quote.json.mode, "fixture");
      assert.equal(quote.json.relayerNonce, "0");
      assert.equal("amountWei" in quote.json, false);
      assert.equal(Number.isNaN(Date.parse(quote.json.expiresAt)), false);
      assert.equal(JSON.stringify(quote.json).includes(SECRET), false);

      const claim = await request(ctx.port, "POST", "/v1/claims", {
        claimId: "claim-1",
        payer: PAYER,
        payee: PAYEE,
        amountWei: "1000",
      });
      assert.equal(claim.status, 200);
      assert.equal(claim.json.ok, true);
      assert.equal(claim.json.mode, "fixture");
      assert.equal(claim.json.claimId, "claim-1");
      assert.equal(claim.json.txHash, null);
      assert.equal(claim.json.reason, "escrow_booked_spencer_run_auth_required");
      assert.equal(claim.json.dryRun, true);
      assert.equal(claim.json.escrowBooked, true);
      assert.equal(claim.json.calldata, null);
      assert.equal(claim.json.calldataStatus, "action_required");

      const echoed = await request(ctx.port, "POST", "/v1/claims/quote", {
        payer: PAYER,
        payee: PAYEE,
        claimId: "claim-2",
        amountWei: "1000",
      });
      assert.equal(echoed.json.amountWei, "1000");

      const log = await readFile(ctx.logPath, "utf8");
      assert.equal(log.includes(SECRET), false);
      assert.equal(log.includes("claim_fixture"), true);
    } finally {
      await ctx.close();
    }
  });

  it("encodes release calldata and still returns a null tx hash", async () => {
    const ctx = await boot();
    const escrowId = "0x" + "11".repeat(32);
    try {
      const claim = await request(ctx.port, "POST", "/v1/claims", { action: "release", claimId: escrowId });
      assert.equal(claim.status, 200);
      assert.equal(claim.json.ok, true);
      assert.equal(claim.json.txHash, null);
      assert.equal(claim.json.action, "release");
      assert.equal(claim.json.signature, "release(bytes32)");
      assert.equal(claim.json.calldataStatus, "encoded");
      assert.equal(claim.json.valueWei, "0");
      assert.equal(claim.json.senderConstraint, "permissionless");
      assert.equal(claim.json.calldata, claim.json.selector + escrowId.slice(2));
      assert.equal(claim.json.reason, "escrow_booked_spencer_run_auth_required");
    } finally {
      await ctx.close();
    }
  });

  it("returns kill_switch and live_submit_blocked", async () => {
    const ctx = await boot({ KILL_SWITCH: "1", ADMIN_SECRET: "admin-test" });
    try {
      const health = await request(ctx.port, "GET", "/v1/health");
      assert.equal(health.status, 200);
      assert.equal(health.json.killSwitch, true);

      const blocked = await request(ctx.port, "POST", "/v1/claims/quote", {
        payer: PAYER,
        payee: PAYEE,
      });
      assert.equal(blocked.status, 503);
      assert.equal(blocked.json.error, "kill_switch");

      const claimBlocked = await request(ctx.port, "POST", "/v1/claims", { claimId: "claim-1" });
      assert.equal(claimBlocked.status, 503);
      assert.equal(claimBlocked.json.error, "kill_switch");

      const unpause = await request(ctx.port, "POST", "/v1/admin/unpause", {}, { "x-admin-secret": "admin-test" });
      assert.equal(unpause.status, 200);
      assert.equal(unpause.json.killSwitch, false);

      const live = await request(ctx.port, "POST", "/v1/claims", { claimId: "claim-1", live: true });
      assert.equal(live.status, 409);
      assert.equal(live.json.ok, false);
      assert.equal(live.json.error, "live_submit_blocked");
      assert.equal(live.json.txHash, null);
      assert.equal(live.json.reason, "escrow_booked_spencer_run_auth_required");
      assert.ok(live.json.blockers.includes("scaffold_never_broadcasts"));
      assert.ok(live.json.blockers.includes("spencer_run_auth_required"));

      const mainnet = await request(ctx.port, "POST", "/v1/claims/quote", {
        payer: PAYER,
        payee: PAYEE,
        chainId: 1,
      });
      assert.equal(mainnet.status, 400);
      assert.equal(mainnet.json.error, "mainnet_refused");

      const other = await request(ctx.port, "POST", "/v1/claims", { claimId: "claim-1", chainId: 11155111 });
      assert.equal(other.status, 400);
      assert.equal(other.json.error, "wrong_chain");
    } finally {
      await ctx.close();
    }
  });

  it("documents a no-op admin route when ADMIN_SECRET is unset", async () => {
    const ctx = await boot({ KILL_SWITCH: "0" });
    try {
      const pause = await request(ctx.port, "POST", "/v1/admin/pause", {}, { "x-admin-secret": "nope" });
      assert.equal(pause.status, 200);
      assert.equal(pause.json.noop, true);
      assert.equal(pause.json.killSwitch, false);
      assert.match(pause.json.docs, /ADMIN_SECRET is unset/);
      const health = await request(ctx.port, "GET", "/health");
      assert.equal(health.json.killSwitch, false);
    } finally {
      await ctx.close();
    }
  });

  it("stays on fixtures when escrow is booked and live submit is requested in env", async () => {
    const ctx = await boot({
      ESCROW_ADDRESS: "0x3333333333333333333333333333333333333333",
      LIVE_SUBMIT: "1",
      SPENCER_RUN_AUTH: "1",
      RELAYER_PRIVATE_KEY: SECRET,
    });
    try {
      const health = await request(ctx.port, "GET", "/health");
      assert.equal(health.json.escrowBooked, true);
      assert.equal(health.json.escrowAddress, "0x3333333333333333333333333333333333333333");
      assert.equal(health.json.liveSubmit, false);
      assert.equal(health.json.liveSubmitRequested, true);
      assert.equal(JSON.stringify(health.json).includes(SECRET), false);

      const claim = await request(ctx.port, "POST", "/v1/claims", { claimId: "claim-booked", mode: "live" });
      assert.equal(claim.status, 409);
      assert.equal(claim.json.error, "live_submit_blocked");
      assert.equal(claim.json.reason, "scaffold_never_broadcasts");
      assert.equal(claim.json.txHash, null);
      assert.ok(claim.json.blockers.includes("scaffold_never_broadcasts"));
      assert.equal(claim.json.blockers.includes("spencer_run_auth_required"), false);
    } finally {
      await ctx.close();
    }
  });
});

async function boot(env = {}) {
  const dir = await mkdtemp(join(tmpdir(), "claim-relayer-"));
  const logPath = join(dir, "claims.jsonl");
  const config = loadConfig({
    CLAIM_LOG_PATH: logPath,
    QUOTE_TTL_MS: "60000",
    RELAYER_PRIVATE_KEY: SECRET,
    ...env,
  });
  const server = createClaimRelayer({
    config,
    killSwitch: createKillSwitch({ initial: config.killSwitchInitial }),
    nonceStore: createNonceStore(),
    claimLog: createClaimLog({ filePath: logPath }),
    now: () => Date.parse("2026-09-25T19:00:00.000Z"),
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const { port } = server.address();
  return {
    port,
    logPath,
    close: () =>
      new Promise((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      }),
  };
}

function request(port, method, path, body, headers = {}) {
  const payload = body === undefined ? null : JSON.stringify(body);
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: "127.0.0.1",
        port,
        path,
        method,
        headers: {
          ...(payload ? { "content-type": "application/json", "content-length": Buffer.byteLength(payload) } : {}),
          ...headers,
        },
      },
      (res) => {
        const chunks = [];
        res.on("data", (chunk) => chunks.push(chunk));
        res.on("end", () => {
          const raw = Buffer.concat(chunks).toString("utf8");
          let json = null;
          try {
            json = raw ? JSON.parse(raw) : null;
          } catch {
            json = null;
          }
          resolve({ status: res.statusCode, json, raw });
        });
      },
    );
    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}
