import { randomBytes } from "node:crypto";
import { BASE_SEPOLIA_CHAIN_ID, ZERO_ADDRESS, httpError, isAddress } from "./config.mjs";
import { encodeEscrowAction } from "./escrowCalldata.mjs";

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

export function refusalReason(config) {
  if (!config?.escrowBooked) return "escrow_not_booked";
  if (!config.liveSubmit?.spencerAuth) return "escrow_booked_spencer_run_auth_required";
  return "scaffold_never_broadcasts";
}

export function liveSubmitError(config) {
  return httpError(409, "live_submit_blocked", {
    reason: refusalReason(config),
    blockers: config.liveSubmit.blockers,
    mode: "fixture",
    txHash: null,
    dryRun: true,
    escrowBooked: config.escrowBooked,
    escrowAddress: config.escrowAddress,
  });
}

/** Encode claim calldata when `action` is set. Never signs or broadcasts. */
export function describeCalldata(body) {
  if (!body || body.action === undefined || body.action === null || String(body.action).trim() === "") {
    return { calldata: null, calldataStatus: "action_required" };
  }
  const encoded = encodeEscrowAction(body);
  return {
    action: encoded.action,
    signature: encoded.signature,
    selector: encoded.selector,
    calldata: encoded.calldata,
    valueWei: encoded.valueWei,
    senderConstraint: encoded.senderConstraint,
    calldataStatus: "encoded",
  };
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
    dryRun: true,
    escrowBooked: config.escrowBooked,
    escrowAddress: config.escrowAddress,
    relayerAddress: config.relayerAddress,
    relayerNonce: reserved.nonce.toString(),
    ...describeCalldata(body),
  };
}

export function buildFixtureClaim(body, config) {
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
    reason: refusalReason(config),
    dryRun: true,
    escrowBooked: Boolean(config.escrowBooked),
    escrowAddress: config.escrowAddress,
    ...describeCalldata(body),
  };
}
