import { defineConfig } from "vitest/config"
import react from "@vitejs/plugin-react"

const port = Number(process.env.PORT) || 5173

export default defineConfig({
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port,
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
