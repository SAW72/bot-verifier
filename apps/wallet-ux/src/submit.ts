import type { Address } from "viem"
import { BASE_SEPOLIA_CHAIN_ID } from "./addresses"
import { BASE_MAINNET_CHAIN_ID, ETHEREUM_MAINNET_CHAIN_ID, type WalletChainId } from "./guard"

export type SubmitCode = "ok" | "disconnected" | "conflict" | "unknown" | "mainnet" | "base-mainnet" | "wrong-chain"

export type SubmitDecision =
  | { ok: true; code: "ok"; chainId: typeof BASE_SEPOLIA_CHAIN_ID }
  | { ok: false; code: Exclude<SubmitCode, "ok">; reason: string }

const SEPOLIA = `Base Sepolia (${BASE_SEPOLIA_CHAIN_ID})`

/** Wallet writes are allowed only while the connected wallet reports Base Sepolia. */
export function evaluateEscrowSubmit(input: {
  walletConnected: boolean
  walletChainId: WalletChainId
}): SubmitDecision {
  if (!input.walletConnected) {
    return {
      ok: false,
      code: "disconnected",
      reason: `Connect a wallet on ${SEPOLIA} to submit.`,
    }
  }
  if (input.walletChainId === "conflict") {
    return {
      ok: false,
      code: "conflict",
      reason: `Wallet chain id is inconsistent. Submit stays off until the wallet reports ${SEPOLIA}.`,
    }
  }
  if (input.walletChainId == null) {
    return {
      ok: false,
      code: "unknown",
      reason: `Wallet chain id is unknown. Submit stays off until the wallet reports ${SEPOLIA}.`,
    }
  }
  if (input.walletChainId === ETHEREUM_MAINNET_CHAIN_ID) {
    return {
      ok: false,
      code: "mainnet",
      reason: `Ethereum mainnet (chain id 1) is refused. Switch to ${SEPOLIA}.`,
    }
  }
  if (input.walletChainId === BASE_MAINNET_CHAIN_ID) {
    return {
      ok: false,
      code: "base-mainnet",
      reason: `Base mainnet (chain id 8453) is refused. Switch to ${SEPOLIA}.`,
    }
  }
  if (input.walletChainId !== BASE_SEPOLIA_CHAIN_ID) {
    return {
      ok: false,
      code: "wrong-chain",
      reason: `Chain id ${input.walletChainId} is refused. Switch to ${SEPOLIA}.`,
    }
  }
  return { ok: true, code: "ok", chainId: BASE_SEPOLIA_CHAIN_ID }
}

export function assertSubmitTarget(to: Address, allowed: readonly Address[]): void {
  const target = to.toLowerCase()
  if (!allowed.some((item) => item.toLowerCase() === target)) {
    throw new Error("Submit target is not the booked Base Sepolia escrow or dispute panel.")
  }
}

export function submitSenderNote(functionName: string): string {
  if (functionName === "createEscrow") {
    return "createEscrow is sent by the connected wallet. It succeeds only when that wallet is the payer's Vault operator. This app does not treat the funding relayer as that operator."
  }
  if (functionName === "dispute") {
    return "dispute() must be sent by the payer or the payee. The connected wallet is the sender."
  }
  if (functionName === "openDispute") {
    return "openDispute is sent to the Base Sepolia dispute panel by the connected wallet."
  }
  return "release and refund are permissionless. The connected wallet sends this transaction on Base Sepolia."
}

export function submitControl(decision: SubmitDecision, pending: boolean): {
  testId: "sepolia-submit" | "submit-refused"
  disabled: boolean
  label: string
} {
  if (!decision.ok) {
    return { testId: "submit-refused", disabled: true, label: decision.reason }
  }
  if (pending) {
    return { testId: "sepolia-submit", disabled: true, label: "Submitting on Base Sepolia…" }
  }
  return { testId: "sepolia-submit", disabled: false, label: "Submit on Base Sepolia" }
}
