import { existsSync, readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { describe, expect, it } from "vitest"
import deploymentBook from "./base-sepolia.json"
import { ADDRESSES, addressBook } from "./addresses"
import { FALLBACK_PIN, fallbackBook, resolveAddressBook, SUPERSEDED } from "./book"

const CANONICAL = {
  coreTimelock: "0x10CC9474b45625ADfd05C209f2518023484878D9",
  denylist: "0xeE76876bECcFc1B58fC06fF4E654a517d784B224",
  vault: "0x1463D664fA467FBCDA4B05443434494f05e565bc",
  disputePanel: "0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb",
  liability: "0x554Caf5a214B8d70D675C09186C5EAE24FEB7307",
  insuranceFund: "0x19fc26B36Cb2031062eD90C19db64b3b09753ab8",
} as const

const canonicalPath = join(
  dirname(fileURLToPath(import.meta.url)),
  "..",
  "..",
  "..",
  "deployments",
  "base-sepolia.json",
)

describe("deployment book", () => {
  it("keeps src/base-sepolia.json equal to deployments/base-sepolia.json", () => {
    expect(existsSync(canonicalPath)).toBe(true)
    expect(deploymentBook).toEqual(JSON.parse(readFileSync(canonicalPath, "utf8")))
  })

  it("reads the canonical live slots and ignores superseded", () => {
    expect(addressBook.source).toBe("deployments/base-sepolia.json")
    expect(addressBook.chainId).toBe(84532)
    expect(ADDRESSES.denylist).toBe(CANONICAL.denylist)
    expect(ADDRESSES.vault).toBe(CANONICAL.vault)
    expect(ADDRESSES.coreTimelock).toBe(CANONICAL.coreTimelock)
    expect(ADDRESSES.disputePanel).toBe(CANONICAL.disputePanel)
    expect(ADDRESSES.liability).toBe(CANONICAL.liability)
    expect(ADDRESSES.insuranceFund).toBe(CANONICAL.insuranceFund)
    expect(ADDRESSES.botAttestationEscrow).toBe("0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c")
    expect(ADDRESSES.bvt).toBeNull()
    expect(JSON.stringify(ADDRESSES).toLowerCase()).not.toContain(SUPERSEDED.denylist.toLowerCase())
    expect(JSON.stringify(ADDRESSES).toLowerCase()).not.toContain(SUPERSEDED.vault.toLowerCase())
    expect(deploymentBook.superseded.Denylist.address).toBe(SUPERSEDED.denylist)
  })

  it("falls back to the corrected pin when the book is not Base Sepolia", () => {
    const book = resolveAddressBook({ ...deploymentBook, chainId: 1 })
    expect(book.source).toBe("fallback-pin")
    expect(book.denylist).toBe(FALLBACK_PIN.denylist)
    expect(book.vault).toBe(FALLBACK_PIN.vault)
    expect(book).toEqual(fallbackBook())
  })

  it("falls back when a live slot is a superseded address", () => {
    const poisoned = structuredClone(deploymentBook)
    poisoned.Denylist.address = SUPERSEDED.denylist
    poisoned.Vault.denylist = SUPERSEDED.denylist
    const book = resolveAddressBook(poisoned)
    expect(book.source).toBe("fallback-pin")
    expect(book.denylist).toBe(CANONICAL.denylist)
    expect(book.vault).toBe(CANONICAL.vault)
  })

  it("falls back when Vault.denylist does not match the live Denylist", () => {
    const drifted = structuredClone(deploymentBook)
    drifted.Vault.denylist = SUPERSEDED.denylist
    expect(resolveAddressBook(drifted).source).toBe("fallback-pin")
  })

  it("accepts a valid book that differs from the pin", () => {
    const next = structuredClone(deploymentBook)
    const replacement = "0x0000000000000000000000000000000000000001"
    next.Denylist.address = replacement
    next.Vault.denylist = replacement
    const book = resolveAddressBook(next)
    expect(book.source).toBe("deployments/base-sepolia.json")
    expect(book.denylist).toBe("0x0000000000000000000000000000000000000001")
    expect(book.vault).toBe(CANONICAL.vault)
  })
})
