import { decodeFunctionData, type Address, type Hex } from "viem"
import { escrowAbi } from "./abi"
import { BASE_SEPOLIA_CHAIN_ID } from "./addresses"
import { BASE_MAINNET_CHAIN_ID, ETHEREUM_MAINNET_CHAIN_ID, type WalletChainId } from "./guard"
import type { CallPreview } from "./preview"
import { evaluateEscrowSubmit } from "./submit"

const RELAYER_ACTIONS = ["createEscrow", "release", "refund", "dispute"] as const

export type RelayerAction = (typeof RELAYER_ACTIONS)[number]

export type RelayerConfig = {
  url: string | null
  secret: string | null
}

export type LiveClaimBody = {
  action: RelayerAction
  claimId: Hex
  chainId: typeof BASE_SEPOLIA_CHAIN_ID
  live: true
  payee?: Address
  payerBotId?: Hex
  payeeBotId?: Hex
  durationSeconds?: string
  amountWei?: string
  disputeId?: Hex
}

export type LiveClaimResult = {
  txHash: Hex
  mode: "live"
}

export class RelayerRequestError extends Error {
  readonly status: number | null
  readonly code: string

  constructor(message: string, status: number | null, code: string) {
    super(message)
    this.name = "RelayerRequestError"
    this.status = status
    this.code = code
  }
}

export function relayerConfigFromEnv(env: {
  VITE_CLAIM_RELAYER_URL?: string
  VITE_CLAIM_API_SECRET?: string
}): RelayerConfig {
  const url = String(env.VITE_CLAIM_RELAYER_URL ?? "").trim().replace(/\/$/, "")
  const secret = String(env.VITE_CLAIM_API_SECRET ?? "").trim()
  return {
    url: url.length > 0 ? url : null,
    secret: secret.length > 0 ? secret : null,
  }
}

/** Connected wallets must already be on Base Sepolia. A disconnected wallet can still use the relayer. */
export function relayerSubmitAllowed(input: {
  walletConnected: boolean
  walletChainId: WalletChainId
}): { ok: true } | { ok: false; reason: string } {
  if (!input.walletConnected) return { ok: true }
  const decision = evaluateEscrowSubmit(input)
  if (!decision.ok) return { ok: false, reason: decision.reason }
  return { ok: true }
}

export function assertRelayerChain(chainId: number): void {
  if (chainId === ETHEREUM_MAINNET_CHAIN_ID || chainId === BASE_MAINNET_CHAIN_ID) {
    throw new RelayerRequestError(
      `Chain id ${chainId} is mainnet. The claim relayer accepts Base Sepolia (${BASE_SEPOLIA_CHAIN_ID}) only.`,
      null,
      "mainnet_refused",
    )
  }
  if (chainId !== BASE_SEPOLIA_CHAIN_ID) {
    throw new RelayerRequestError(
      `Chain id ${chainId} is refused. The claim relayer accepts Base Sepolia (${BASE_SEPOLIA_CHAIN_ID}) only.`,
      null,
      "wrong_chain",
    )
  }
}

function isRelayerAction(name: string): name is RelayerAction {
  return (RELAYER_ACTIONS as readonly string[]).includes(name)
}

function asHex32(value: unknown, field: string): Hex {
  if (typeof value !== "string" || !/^0x[0-9a-fA-F]{64}$/.test(value)) {
    throw new RelayerRequestError(`Claim relayer needs a bytes32 ${field}.`, null, "invalid_bytes32")
  }
  return value as Hex
}

function asAddress(value: unknown, field: string): Address {
  if (typeof value !== "string" || !/^0x[0-9a-fA-F]{40}$/.test(value)) {
    throw new RelayerRequestError(`Claim relayer needs an address ${field}.`, null, "invalid_address")
  }
  return value as Address
}

export function claimBodyFromPreview(preview: CallPreview): LiveClaimBody {
  assertRelayerChain(BASE_SEPOLIA_CHAIN_ID)
  if (preview.functionName === "openDispute") {
    throw new RelayerRequestError(
      "The claim relayer submits escrow actions only. openDispute stays on the connected wallet.",
      null,
      "action_not_claim",
    )
  }
  if (!isRelayerAction(preview.functionName)) {
    throw new RelayerRequestError(
      "The claim relayer submits createEscrow, release, refund, and dispute only.",
      null,
      "action_not_claim",
    )
  }
  const decoded = decodeFunctionData({ abi: escrowAbi, data: preview.calldata })
  if (decoded.functionName !== preview.functionName) {
    throw new RelayerRequestError("Calldata does not match the preview action.", null, "calldata_mismatch")
  }
  const args = decoded.args ?? []
  if (preview.functionName === "createEscrow") {
    const duration = args[4]
    if (typeof duration !== "bigint") {
      throw new RelayerRequestError("Claim relayer needs durationSeconds.", null, "invalid_duration")
    }
    if (preview.valueWei <= 0n) {
      throw new RelayerRequestError("createEscrow needs a positive value for the relayer.", null, "invalid_amount")
    }
    return {
      action: "createEscrow",
      claimId: asHex32(args[0], "escrowId"),
      payee: asAddress(args[1], "payee"),
      payerBotId: asHex32(args[2], "payerBotId"),
      payeeBotId: asHex32(args[3], "payeeBotId"),
      durationSeconds: duration.toString(),
      amountWei: preview.valueWei.toString(),
      chainId: BASE_SEPOLIA_CHAIN_ID,
      live: true,
    }
  }
  if (preview.functionName === "dispute") {
    return {
      action: "dispute",
      claimId: asHex32(args[0], "escrowId"),
      disputeId: asHex32(args[1], "disputeId"),
      chainId: BASE_SEPOLIA_CHAIN_ID,
      live: true,
    }
  }
  return {
    action: preview.functionName,
    claimId: asHex32(args[0], "escrowId"),
    chainId: BASE_SEPOLIA_CHAIN_ID,
    live: true,
  }
}

function claimsEndpoint(url: string): string {
  let parsed: URL
  try {
    parsed = new URL(url)
  } catch {
    throw new RelayerRequestError("VITE_CLAIM_RELAYER_URL is not a valid URL.", null, "invalid_relayer_url")
  }
  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    throw new RelayerRequestError("VITE_CLAIM_RELAYER_URL must be http or https.", null, "invalid_relayer_url")
  }
  if (parsed.username || parsed.password) {
    throw new RelayerRequestError("VITE_CLAIM_RELAYER_URL must not include credentials.", null, "invalid_relayer_url")
  }
  const base = `${parsed.origin}${parsed.pathname.replace(/\/$/, "")}`
  return base.endsWith("/v1/claims") ? base : `${base}/v1/claims`
}

async function readJson(response: Response): Promise<Record<string, unknown> | null> {
  const text = await response.text()
  if (!text) return null
  try {
    const parsed: unknown = JSON.parse(text)
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return null
    return parsed as Record<string, unknown>
  } catch {
    return null
  }
}

function errorFromResponse(status: number, body: Record<string, unknown> | null): RelayerRequestError {
  const error = typeof body?.error === "string" ? body.error : "request_failed"
  const reason = typeof body?.reason === "string" ? body.reason : ""
  if (status === 401 || error === "unauthorized") {
    return new RelayerRequestError(
      "Claim relayer refused the live claim (401 unauthorized). Check VITE_CLAIM_API_SECRET against CLAIM_API_SECRET on the relayer.",
      401,
      "unauthorized",
    )
  }
  if (status === 503 && error === "claim_api_secret_required") {
    return new RelayerRequestError(
      "Claim relayer live submit is allowed but CLAIM_API_SECRET is unset (503 claim_api_secret_required). The claim was not broadcast.",
      503,
      "claim_api_secret_required",
    )
  }
  if (status === 503 && error === "kill_switch") {
    return new RelayerRequestError("Claim relayer kill switch is on (503). The live claim was not broadcast.", 503, "kill_switch")
  }
  if (status === 503) {
    return new RelayerRequestError(
      `Claim relayer is unavailable (503 ${error}). The live claim was not broadcast.`,
      503,
      error,
    )
  }
  const detail = reason ? `${error} (${reason})` : error
  return new RelayerRequestError(`Claim relayer rejected the live claim (${status} ${detail}).`, status, error)
}

export function relayerErrorText(error: unknown): string {
  if (error instanceof RelayerRequestError) return error.message
  if (error instanceof Error && error.message.length > 0) return error.message
  return "Claim relayer request failed."
}

/**
 * POST /v1/claims with live:true. Sends x-claim-secret only when a secret is set.
 * Chain id must be Base Sepolia (84532). Mainnet is refused before fetch.
 */
export async function postLiveClaim(input: {
  url: string
  secret?: string | null
  body: LiveClaimBody
  fetchImpl?: typeof fetch
}): Promise<LiveClaimResult> {
  assertRelayerChain(input.body.chainId)
  if (input.body.live !== true) {
    throw new RelayerRequestError("Relayer submits must set live: true.", null, "live_required")
  }
  const endpoint = claimsEndpoint(input.url)
  const headers: Record<string, string> = { "content-type": "application/json" }
  const secret = String(input.secret ?? "").trim()
  if (secret) headers["x-claim-secret"] = secret
  const fetchImpl = input.fetchImpl ?? fetch
  let response: Response
  try {
    response = await fetchImpl(endpoint, {
      method: "POST",
      headers,
      body: JSON.stringify(input.body),
    })
  } catch {
    throw new RelayerRequestError(
      "Could not reach the claim relayer. If this is the Pages site, CORS on Render must allow this origin (https://agent-a-wallet-ux.pages.dev) and the x-claim-secret header.",
      null,
      "cors_or_network",
    )
  }
  const json = await readJson(response)
  if (!response.ok) throw errorFromResponse(response.status, json)
  const txHash = json?.txHash
  if (json?.ok !== true || json.mode !== "live" || typeof txHash !== "string" || !/^0x[0-9a-fA-F]{64}$/.test(txHash)) {
    throw new RelayerRequestError("Claim relayer did not return a live transaction hash.", response.status, "missing_tx_hash")
  }
  return { txHash: txHash as Hex, mode: "live" }
}
