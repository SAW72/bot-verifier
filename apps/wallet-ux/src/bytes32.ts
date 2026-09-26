const HEX_64 = /^[0-9a-fA-F]{64}$/

export function parseBytes32(raw: string): `0x${string}` | null {
  const trimmed = raw.trim()
  if (trimmed.length === 0) return null
  const hex = trimmed.startsWith("0x") || trimmed.startsWith("0X") ? trimmed.slice(2) : trimmed
  if (!HEX_64.test(hex)) return null
  return `0x${hex.toLowerCase()}`
}

const MATCH_LEVELS = ["None", "PromptBlock", "SignatureBlock", "ExactBlock"] as const

export function matchLevelLabel(level: number): string {
  return MATCH_LEVELS[level] ?? `Unknown(${level})`
}
