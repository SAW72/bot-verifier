/**
 * Frontend address book for Base Sepolia (chain id 84532) only.
 *
 * Live slots are read from deployments/base-sepolia.json. The corrected Gate A
 * pin is the fallback when that file is missing or fails validation. The
 * superseded Denylist (0xF0f2…) and Vault (0xa1a0…) are never read targets.
 * There is no mainnet book.
 */

import deploymentBook from "../../../deployments/base-sepolia.json"
import {
  BASE_SEPOLIA_CHAIN_ID,
  FALLBACK_PIN,
  resolveAddressBook,
  SUPERSEDED,
  ZERO_ADDRESS,
} from "./book"

export { BASE_SEPOLIA_CHAIN_ID, FALLBACK_PIN, SUPERSEDED, ZERO_ADDRESS }

export const addressBook = resolveAddressBook(deploymentBook)

/** Live slots. Same object the UI and the contract reads use. */
export const ADDRESSES = addressBook

export const CORE_TIMELOCK = ADDRESSES.coreTimelock

export const NOT_DEPLOYED = [
  ["BotAttestationEscrow", ADDRESSES.botAttestationEscrow],
  ["BVT", ADDRESSES.bvt],
  ["BVTStaking", ADDRESSES.bvtStaking],
  ["BVTFeeRouter", ADDRESSES.bvtFeeRouter],
  ["BVTTimelock", ADDRESSES.bvtTimelock],
  ["BVTGovernor", ADDRESSES.bvtGovernor],
] as const
