import { createPublicClient, getAddress, http, isAddress, type Address } from "viem"
import { baseSepolia } from "viem/chains"
import { denylistAbi, disputePanelAbi, insuranceFundAbi, liabilityAbi, vaultAbi } from "./abi"
import { ADDRESSES, BASE_SEPOLIA_CHAIN_ID } from "./addresses"

export const DEFAULT_RPC_URL = "https://sepolia.base.org"

export function rpcUrlFromEnv(value: string | undefined): string {
  const trimmed = value?.trim()
  return trimmed ? trimmed : DEFAULT_RPC_URL
}

export function rpcHost(url: string): string {
  try {
    return new URL(url).host
  } catch {
    return "unparsed RPC URL"
  }
}

export function createSepoliaClient(url: string) {
  return createPublicClient({
    chain: baseSepolia,
    transport: http(url, { timeout: 20_000 }),
  })
}

export type SepoliaClient = ReturnType<typeof createSepoliaClient>

export type GateStatus = {
  chainId: number
  denylist: { owner: Address; pendingOwner: Address }
  vault: { owner: Address; pendingOwner: Address; denylist: Address }
  disputePanel: { owner: Address; arbitratorCount: bigint; panelSize: bigint }
  liability: { owner: Address; insurance: Address; nativeBalanceWei: bigint }
  insuranceFund: {
    owner: Address
    liability: Address
    recordedBalanceWei: bigint
    nativeBalanceWei: bigint
  }
}

export type Membership = {
  exact: boolean
  signature: boolean
  prompt: boolean
}

export function panelNotSeated(arbitratorCount: bigint, panelSize: bigint): boolean {
  return arbitratorCount < panelSize
}

function asAddress(value: unknown, label: string): Address {
  if (typeof value !== "string" || !isAddress(value)) {
    throw new Error(`Expected an address from ${label}.`)
  }
  return getAddress(value)
}

function asBigint(value: unknown, label: string): bigint {
  if (typeof value === "bigint") return value
  throw new Error(`Expected a uint from ${label}.`)
}

function asBool(value: unknown, label: string): boolean {
  if (typeof value !== "boolean") throw new Error(`Expected a bool from ${label}.`)
  return value
}

function asLevel(value: unknown): number {
  if (typeof value === "number" && Number.isInteger(value)) return value
  if (typeof value === "bigint") return Number(value)
  throw new Error("Expected a match level from check().")
}

async function assertSepoliaRpc(client: SepoliaClient): Promise<number> {
  const chainId = await client.getChainId()
  if (chainId !== BASE_SEPOLIA_CHAIN_ID) {
    throw new Error(
      `Refusing reads on chain id ${chainId}. This client only talks to Base Sepolia (${BASE_SEPOLIA_CHAIN_ID}).`,
    )
  }
  return chainId
}

const PINNED_CODE = [
  ["Denylist", ADDRESSES.denylist],
  ["Vault", ADDRESSES.vault],
  ["DisputePanel", ADDRESSES.disputePanel],
  ["Liability", ADDRESSES.liability],
  ["InsuranceFund", ADDRESSES.insuranceFund],
] as const

export async function readGateStatus(client: SepoliaClient): Promise<GateStatus> {
  const chainId = await assertSepoliaRpc(client)

  const code = await Promise.all(
    PINNED_CODE.map(async ([label, address]) => {
      const bytecode = await client.getBytecode({ address })
      return { label, address, empty: bytecode == null || bytecode === "0x" }
    }),
  )
  const missing = code.filter((row) => row.empty)
  if (missing.length > 0) {
    const listed = missing.map((row) => `${row.label} ${row.address}`).join(", ")
    throw new Error(`No contract code at ${listed}.`)
  }

  const [packed, liabilityNative, insuranceNative] = await Promise.all([
    client.multicall({
      allowFailure: false,
      contracts: [
        { address: ADDRESSES.denylist, abi: denylistAbi, functionName: "owner" },
        { address: ADDRESSES.denylist, abi: denylistAbi, functionName: "pendingOwner" },
        { address: ADDRESSES.vault, abi: vaultAbi, functionName: "owner" },
        { address: ADDRESSES.vault, abi: vaultAbi, functionName: "pendingOwner" },
        { address: ADDRESSES.vault, abi: vaultAbi, functionName: "denylist" },
        { address: ADDRESSES.disputePanel, abi: disputePanelAbi, functionName: "owner" },
        { address: ADDRESSES.disputePanel, abi: disputePanelAbi, functionName: "arbitratorCount" },
        { address: ADDRESSES.disputePanel, abi: disputePanelAbi, functionName: "PANEL_SIZE" },
        { address: ADDRESSES.liability, abi: liabilityAbi, functionName: "owner" },
        { address: ADDRESSES.liability, abi: liabilityAbi, functionName: "insurance" },
        { address: ADDRESSES.insuranceFund, abi: insuranceFundAbi, functionName: "owner" },
        { address: ADDRESSES.insuranceFund, abi: insuranceFundAbi, functionName: "liability" },
        { address: ADDRESSES.insuranceFund, abi: insuranceFundAbi, functionName: "balance" },
      ],
    }),
    client.getBalance({ address: ADDRESSES.liability }),
    client.getBalance({ address: ADDRESSES.insuranceFund }),
  ])

  const [
    denylistOwner,
    denylistPending,
    vaultOwner,
    vaultPending,
    vaultDenylist,
    panelOwner,
    arbitratorCount,
    panelSize,
    liabilityOwner,
    liabilityInsurance,
    insuranceOwner,
    insuranceLiability,
    insuranceBalance,
  ] = packed

  return {
    chainId,
    denylist: {
      owner: asAddress(denylistOwner, "Denylist.owner"),
      pendingOwner: asAddress(denylistPending, "Denylist.pendingOwner"),
    },
    vault: {
      owner: asAddress(vaultOwner, "Vault.owner"),
      pendingOwner: asAddress(vaultPending, "Vault.pendingOwner"),
      denylist: asAddress(vaultDenylist, "Vault.denylist"),
    },
    disputePanel: {
      owner: asAddress(panelOwner, "DisputePanel.owner"),
      arbitratorCount: asBigint(arbitratorCount, "DisputePanel.arbitratorCount"),
      panelSize: asBigint(panelSize, "DisputePanel.PANEL_SIZE"),
    },
    liability: {
      owner: asAddress(liabilityOwner, "Liability.owner"),
      insurance: asAddress(liabilityInsurance, "Liability.insurance"),
      nativeBalanceWei: liabilityNative,
    },
    insuranceFund: {
      owner: asAddress(insuranceOwner, "InsuranceFund.owner"),
      liability: asAddress(insuranceLiability, "InsuranceFund.liability"),
      recordedBalanceWei: asBigint(insuranceBalance, "InsuranceFund.balance"),
      nativeBalanceWei: insuranceNative,
    },
  }
}

export async function readMembership(client: SepoliaClient, id: `0x${string}`): Promise<Membership> {
  await assertSepoliaRpc(client)
  const [exact, signature, prompt] = await client.multicall({
    allowFailure: false,
    contracts: [
      { address: ADDRESSES.denylist, abi: denylistAbi, functionName: "denylistedHashes", args: [id] },
      { address: ADDRESSES.denylist, abi: denylistAbi, functionName: "denylistedSignatures", args: [id] },
      { address: ADDRESSES.denylist, abi: denylistAbi, functionName: "denylistedPrompts", args: [id] },
    ],
  })
  return {
    exact: asBool(exact, "denylistedHashes"),
    signature: asBool(signature, "denylistedSignatures"),
    prompt: asBool(prompt, "denylistedPrompts"),
  }
}

export async function readCheck(
  client: SepoliaClient,
  weightHash: `0x${string}`,
  behaviorSig: `0x${string}`,
  promptHash: `0x${string}`,
): Promise<number> {
  await assertSepoliaRpc(client)
  const level = await client.readContract({
    address: ADDRESSES.denylist,
    abi: denylistAbi,
    functionName: "check",
    args: [weightHash, behaviorSig, promptHash],
  })
  return asLevel(level)
}
