import { formatEther } from "viem"
import { ZERO_ADDRESS } from "./addresses"

export function sameAddress(a: string, b: string): boolean {
  return a.toLowerCase() === b.toLowerCase()
}

export function shortAddress(address: string): string {
  if (address.length < 12) return address
  return `${address.slice(0, 6)}…${address.slice(-4)}`
}

export function formatEth(wei: bigint): string {
  return `${formatEther(wei)} ETH`
}

export function isZeroAddress(address: string): boolean {
  return sameAddress(address, ZERO_ADDRESS)
}

export function errorText(error: unknown): string {
  if (typeof error === "object" && error !== null && "shortMessage" in error) {
    const short = error.shortMessage
    if (typeof short === "string" && short.length > 0) return short
  }
  if (error instanceof Error && error.message.length > 0) return error.message
  return "Request failed"
}
