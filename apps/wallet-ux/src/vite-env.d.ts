/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_BASE_SEPOLIA_RPC_URL?: string
  /** Public Base Sepolia claim-relayer origin. Unset keeps escrow submits wallet-direct. */
  readonly VITE_CLAIM_RELAYER_URL?: string
  /**
   * Optional. Sent as x-claim-secret on live POST /v1/claims.
   * Vite inlines this into the static build. That is a soft deterrent for a Sepolia test, not browser security.
   */
  readonly VITE_CLAIM_API_SECRET?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
