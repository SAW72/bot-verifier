import type { Abi } from "viem"
import denylistAbiJson from "./abi/Denylist.json"
import disputePanelAbiJson from "./abi/DisputePanel.json"
import insuranceFundAbiJson from "./abi/InsuranceFund.json"
import liabilityAbiJson from "./abi/Liability.json"
import vaultAbiJson from "./abi/Vault.json"

export const denylistAbi = denylistAbiJson as Abi
export const vaultAbi = vaultAbiJson as Abi
export const disputePanelAbi = disputePanelAbiJson as Abi
export const liabilityAbi = liabilityAbiJson as Abi
export const insuranceFundAbi = insuranceFundAbiJson as Abi
