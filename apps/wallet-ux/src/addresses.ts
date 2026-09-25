/**
 * Frontend address pin for Base Sepolia (chain id 84532) only.
 *
 * Live Denylist and Vault are the post-redeploy pair. Do not point reads at the
 * superseded contracts (old Denylist 0xF0f2… / old Vault 0xa1a0…). Those stay
 * on chain under `SUPERSEDED` so this module cannot silently drift back.
 *
 * Escrow and the BVT stack are null until they are deployed. Do not invent
 * addresses. There is no mainnet book.
 */

export const BASE_SEPOLIA_CHAIN_ID = 84532 as const

export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000" as const

export const CORE_TIMELOCK = "0x10CC9474b45625ADfd05C209f2518023484878D9" as const

export const ADDRESSES = {
  chainId: BASE_SEPOLIA_CHAIN_ID,
  network: "base-sepolia",
  coreTimelock: CORE_TIMELOCK,
  denylist: "0xeE76876bECcFc1B58fC06fF4E654a517d784B224",
  vault: "0x1463D664fA467FBCDA4B05443434494f05e565bc",
  disputePanel: "0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb",
  liability: "0x554Caf5a214B8d70D675C09186C5EAE24FEB7307",
  insuranceFund: "0x19fc26B36Cb2031062eD90C19db64b3b09753ab8",
  botAttestationEscrow: null,
  bvt: null,
  bvtStaking: null,
  bvtFeeRouter: null,
  bvtTimelock: null,
  bvtGovernor: null,
} as const

/** Previous Denylist and Vault. Still on chain. Not a read target. */
export const SUPERSEDED = {
  denylist: "0xF0f260967D377E07Bdd7840862508ddB23C012b8",
  vault: "0xa1a067D2F58Ae54d4bb5Ec06d893B29E23A45CB7",
} as const

export const NOT_DEPLOYED = [
  ["BotAttestationEscrow", ADDRESSES.botAttestationEscrow],
  ["BVT", ADDRESSES.bvt],
  ["BVTStaking", ADDRESSES.bvtStaking],
  ["BVTFeeRouter", ADDRESSES.bvtFeeRouter],
  ["BVTTimelock", ADDRESSES.bvtTimelock],
  ["BVTGovernor", ADDRESSES.bvtGovernor],
] as const
