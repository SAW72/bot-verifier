import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vitest/config"
import react from "@vitejs/plugin-react"

const port = Number(process.env.PORT) || 5173
const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../..")

export default defineConfig({
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port,
    fs: { allow: [repoRoot] },
  },
  preview: {
    host: "0.0.0.0",
    port: Number(process.env.PORT) || 4173,
  },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
})
