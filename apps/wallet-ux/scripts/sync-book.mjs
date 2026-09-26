import { copyFileSync, mkdirSync, readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const appRoot = join(here, "..")
const repoRoot = join(appRoot, "..", "..")
const source = join(repoRoot, "deployments", "base-sepolia.json")
const destDir = join(appRoot, "src", "generated")
const dest = join(destDir, "base-sepolia.json")

const book = JSON.parse(readFileSync(source, "utf8"))
if (book.chainId !== 84532 || book.network !== "base-sepolia") {
  throw new Error(
    `Refusing to copy address book: expected Base Sepolia chainId 84532, got chainId=${book.chainId} network=${book.network}`,
  )
}

mkdirSync(destDir, { recursive: true })
copyFileSync(source, dest)
console.log("Copied deployments/base-sepolia.json -> src/generated/base-sepolia.json (chainId 84532)")
