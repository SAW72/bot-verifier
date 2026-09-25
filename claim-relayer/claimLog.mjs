import { appendFile, mkdir } from "node:fs/promises";
import { dirname } from "node:path";

const ALLOWED = new Set([
  "event",
  "ts",
  "claimId",
  "payer",
  "payee",
  "amountWei",
  "fixture",
  "mode",
  "expiresAt",
  "chainId",
  "escrowBooked",
  "relayerAddress",
  "relayerNonce",
  "txHash",
  "reason",
  "error",
  "attempt",
  "attempts",
  "ok",
  "killSwitch",
  "status",
  "field",
]);

/**
 * Keep an allowlisted flat record. Nested objects and secret-shaped strings
 * are dropped so a request body cannot land a key in the JSONL file.
 */
export function sanitizeLogRecord(record) {
  const out = {};
  if (!record || typeof record !== "object") return out;
  for (const key of ALLOWED) {
    if (record[key] === undefined) continue;
    const value = record[key];
    if (value === null || typeof value === "boolean" || typeof value === "number") {
      out[key] = value;
      continue;
    }
    if (typeof value === "bigint") {
      out[key] = value.toString();
      continue;
    }
    if (typeof value === "string") {
      if (/private[_-]?key|secret|mnemonic|seed phrase/i.test(value)) continue;
      out[key] = value.slice(0, 300);
    }
  }
  return out;
}

/**
 * Append-only JSONL. filePath comes from CLAIM_LOG_PATH.
 * @param {{ filePath?: string, now?: () => number }} [opts]
 */
export function createClaimLog(opts = {}) {
  const filePath = opts.filePath || "./data/claims.jsonl";
  const now = opts.now || Date.now;
  let ready = null;

  async function ensureDir() {
    if (!ready) ready = mkdir(dirname(filePath), { recursive: true });
    await ready;
  }

  async function append(event) {
    await ensureDir();
    const record = sanitizeLogRecord({
      ts: new Date(now()).toISOString(),
      ...event,
    });
    await appendFile(filePath, `${JSON.stringify(record)}\n`, { mode: 0o600 });
    return record;
  }

  return { append, filePath, sanitizeLogRecord };
}
