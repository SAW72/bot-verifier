import { randomBytes } from "node:crypto";
import { BASE_SEPOLIA_CHAIN_ID, ZERO_ADDRESS, httpError, isAddress } from "./config.mjs";

const CLAIM_ID_RE = /^(?:fixture-[0-9a-f]{8,32}|0x[0-9a-fA-F]{64}|[A-Za-z0-9:_-]{1,80})$/;

export function assertBaseSepolia(body) {
  if (!body || body.chainId === undefined || body.chainId === null || body.chainId === "") return;
  const chainId = Number(body.chainId);
  if (!Number.isInteger(chainId)) throw httpError(400, "wrong_chain");
  if (chainId === 1 || chainId === 8453) throw httpError(400, "mainnet_refused", { chainId });
  if (chainId !== BASE_SEPOLIA_CHAIN_ID) throw httpError(400, "wrong_chain", { chainId });
}

export function requireAddress(value, field) {
  const address = String(value || "").trim();
  if (!isAddress(address) || address.toLowerCase() === ZERO_ADDRESS) {
    throw httpError(400, "invalid_address", { field });
  }
  return address;
}

export function parseAmountWei(value) {
  if (value === undefined || value === null || value === "") return undefined;
  if (typeof value === "number") {
    if (!Number.isSafeInteger(value)) throw httpError(400, "invalid_amount");
  } else if (typeof value !== "string" && typeof value !== "bigint") {
    throw httpError(400, "invalid_amount");
  }
  const text = typeof value === "bigint" ? value.toString() : String(value).trim();
  if (!/^[0-9]+$/.test(text) || text === "0") throw httpError(400, "invalid_amount");
  return text;
}

export function newFixtureClaimId() {
  return `fixture-${randomBytes(8).toString("hex")}`;
}

export function parseClaimId(value, { generate = false } = {}) {
  if (value === undefined || value === null || String(value).trim() === "") {
    if (generate) return newFixtureClaimId();
    throw httpError(400, "invalid_claim_id");
  }
  const claimId = String(value).trim();
  if (!CLAIM_ID_RE.test(claimId)) throw httpError(400, "invalid_claim_id");
  return claimId;
}

/** Client asked for a real transaction. This scaffold always refuses. */
export function wantsLiveSubmit(body) {
  if (!body || typeof body !== "object") return false;
  const mode = String(body.mode || "").trim().toLowerCase();
  return body.live === true || body.liveSubmit === true || mode === "live" || mode === "broadcast";
}

export function refuseLiveSubmit() {
  throw httpError(409, "live_submit_blocked", {
    reason: "awaiting_escrow_booking_and_spencer_run_auth",
    mode: "fixture",
    txHash: null,
  });
}

/**
 * TODO(Builder): lock the claim calldata ABI, then encode BotAttestationEscrow
 * createEscrow / release / refund here. Do not broadcast from this function.
 * Live submit stays off until Escrow is booked and Spencer authorizes the run.
 */
export function todoEscrowCalldata() {
  throw httpError(409, "live_submit_blocked", {
    reason: "claim_calldata_abi_not_locked",
    mode: "fixture",
    txHash: null,
  });
}

export async function buildFixtureQuote({ body, config, nonceStore, now }) {
  assertBaseSepolia(body);
  const payer = requireAddress(body.payer, "payer");
  const payee = requireAddress(body.payee, "payee");
  if (payer.toLowerCase() === payee.toLowerCase()) throw httpError(400, "invalid_parties");
  const claimId = parseClaimId(body.claimId, { generate: true });
  const amountWei = parseAmountWei(body.amountWei);
  const atMs = now();
  const reserved = await nonceStore.reserve({
    claimId,
    ttlMs: config.quoteTtlMs,
    atMs,
  });
  return {
    claimId,
    payer,
    payee,
    ...(amountWei !== undefined ? { amountWei } : {}),
    fixture: true,
    expiresAt: new Date(reserved.expiresAtMs).toISOString(),
    chainId: BASE_SEPOLIA_CHAIN_ID,
    mode: "fixture",
    escrowBooked: config.escrowBooked,
    relayerAddress: config.relayerAddress,
    relayerNonce: reserved.nonce.toString(),
  };
}

export function buildFixtureClaim(body) {
  assertBaseSepolia(body);
  const claimId = parseClaimId(body.claimId);
  const payer = body.payer !== undefined ? requireAddress(body.payer, "payer") : undefined;
  const payee = body.payee !== undefined ? requireAddress(body.payee, "payee") : undefined;
  if (payer && payee && payer.toLowerCase() === payee.toLowerCase()) {
    throw httpError(400, "invalid_parties");
  }
  if (body.amountWei !== undefined && body.amountWei !== null && body.amountWei !== "") {
    parseAmountWei(body.amountWei);
  }
  return {
    ok: true,
    mode: "fixture",
    claimId,
    txHash: null,
    reason: "live_submit_blocked",
  };
}
