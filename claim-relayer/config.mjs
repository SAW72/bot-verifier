/**
 * Base Sepolia (chainId 84532) only.
 * This module never reads RELAYER_PRIVATE_KEY and never opens an RPC client.
 * Escrow defaults from deployments/base-sepolia.json when ESCROW_ADDRESS is unset.
 */

import { loadAddressBook, DEFAULT_ADDRESS_BOOK } from "./addressBook.mjs";

export const BASE_SEPOLIA_CHAIN_ID = 84532;
export const DEFAULT_RELAYER_ADDRESS = "0x9D1b3E1400D2632d435cB7C0fC131C4f42B31861";
export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

const ADDRESS_RE = /^0x[0-9a-fA-F]{40}$/;
const MAINNET_CHAIN_IDS = new Set([1, 8453]);

export function parseEnvFlag(value) {
  const v = String(value ?? "")
    .trim()
    .toLowerCase();
  return v === "1" || v === "true" || v === "yes" || v === "on";
}

export function isAddress(value) {
  return ADDRESS_RE.test(String(value || "").trim());
}

/** Preserve checksum casing. Return null when the shape is wrong. */
export function checkedAddress(value) {
  const s = String(value || "").trim();
  if (!ADDRESS_RE.test(s)) return null;
  return s;
}

export function httpError(status, error, extra = {}) {
  return Object.assign(new Error(error), { status, error, ...extra });
}

/**
 * Live submit stays blocked in this scaffold.
 * A later build may broadcast only when LIVE_SUBMIT=1, ESCROW_ADDRESS is booked,
 * and Spencer sets SPENCER_RUN_AUTH=1. This function never returns allowed=true.
 */
export function liveSubmitStatus(env, escrowBooked) {
  const requested = parseEnvFlag(env.LIVE_SUBMIT);
  const spencerAuth = parseEnvFlag(env.SPENCER_RUN_AUTH);
  const blockers = ["scaffold_never_broadcasts", "encode_only_no_broadcast"];
  if (escrowBooked) blockers.push("escrow_booked");
  else blockers.push("escrow_not_booked");
  if (!spencerAuth) blockers.push("spencer_run_auth_required");
  if (!requested) blockers.push("live_submit_off");
  return {
    requested,
    allowed: false,
    spencerAuth,
    error: "live_submit_blocked",
    blockers,
  };
}

function resolveEscrow(env) {
  const book = loadAddressBook(env.ADDRESS_BOOK_PATH || DEFAULT_ADDRESS_BOOK);
  const base = {
    disputePanelAddress: book.disputePanelAddress,
    coreTimelock: book.coreTimelock,
    escrowOwner: book.escrowOwner,
    bvtAddress: book.bvtAddress,
  };
  const explicit = env.ESCROW_ADDRESS === undefined ? "" : String(env.ESCROW_ADDRESS).trim();
  if (!explicit) {
    return {
      ...base,
      escrowAddress: book.escrowAddress,
      escrowBooked: book.escrowBooked,
      escrowSource: "address_book",
    };
  }
  const parsed = checkedAddress(explicit);
  if (!parsed) throw httpError(400, "invalid_escrow_address");
  if (parsed.toLowerCase() === ZERO_ADDRESS) {
    return { ...base, escrowAddress: null, escrowBooked: false, escrowSource: "env_cleared" };
  }
  return { ...base, escrowAddress: parsed, escrowBooked: true, escrowSource: "env" };
}

export function loadConfig(env = process.env) {
  if (env.RELAYER_KEY_FILE || env.RELAYER_PRIVATE_KEY_FILE) {
    throw httpError(500, "key_file_forbidden");
  }

  const chainText = env.CHAIN_ID === undefined ? "" : String(env.CHAIN_ID).trim();
  const chainId = chainText === "" ? BASE_SEPOLIA_CHAIN_ID : Number(chainText);
  if (!Number.isInteger(chainId)) {
    throw httpError(400, "wrong_chain", { chainId: chainText });
  }
  if (chainId !== BASE_SEPOLIA_CHAIN_ID) {
    const error = MAINNET_CHAIN_IDS.has(chainId) ? "mainnet_refused" : "wrong_chain";
    throw httpError(400, error, { chainId });
  }

  let relayerAddress = DEFAULT_RELAYER_ADDRESS;
  if (env.RELAYER_ADDRESS !== undefined && String(env.RELAYER_ADDRESS).trim() !== "") {
    const parsed = checkedAddress(env.RELAYER_ADDRESS);
    if (!parsed || parsed.toLowerCase() === ZERO_ADDRESS) {
      throw httpError(400, "invalid_relayer_address");
    }
    relayerAddress = parsed;
  }

  const escrow = resolveEscrow(env);

  const port = Number(env.PORT === undefined || String(env.PORT).trim() === "" ? 8790 : env.PORT);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw httpError(400, "invalid_port");
  }

  const ttlRaw = Number(env.QUOTE_TTL_MS || 30 * 60 * 1000);
  const quoteTtlMs = Number.isFinite(ttlRaw) && ttlRaw > 0 ? ttlRaw : 30 * 60 * 1000;

  return {
    chainId: BASE_SEPOLIA_CHAIN_ID,
    network: "base-sepolia",
    port,
    host: env.HOST || (env.RENDER ? "0.0.0.0" : "127.0.0.1"),
    relayerAddress,
    escrowAddress: escrow.escrowAddress,
    escrowBooked: escrow.escrowBooked,
    escrowSource: escrow.escrowSource,
    disputePanelAddress: escrow.disputePanelAddress,
    coreTimelock: escrow.coreTimelock,
    escrowOwner: escrow.escrowOwner,
    bvtAddress: escrow.bvtAddress,
    adminSecret: String(env.ADMIN_SECRET || "").trim(),
    killSwitchInitial: parseEnvFlag(env.KILL_SWITCH),
    claimLogPath: String(env.CLAIM_LOG_PATH || "./data/claims.jsonl"),
    quoteTtlMs,
    liveSubmit: liveSubmitStatus(env, escrow.escrowBooked),
    corsOrigins: env.CORS_ORIGINS || "http://localhost:5173,http://127.0.0.1:5173",
  };
}

export function healthPayload(config, killSwitchOn) {
  return {
    ok: true,
    chainId: config.chainId,
    network: config.network,
    killSwitch: Boolean(killSwitchOn),
    mode: "fixture",
    stub: true,
    fixture: true,
    escrowBooked: config.escrowBooked,
    escrowAddress: config.escrowAddress,
    escrowSource: config.escrowSource,
    relayerAddress: config.relayerAddress,
    liveSubmit: false,
    liveSubmitRequested: config.liveSubmit.requested,
    liveSubmitBlockers: config.liveSubmit.blockers,
  };
}
