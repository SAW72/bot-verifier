# Cloudflare Pages (wallet UX)

Repo config only. Nothing in this repository creates a Pages project or publishes the site. Create the project and publish only after Spencer GO. Do not run `wrangler pages deploy` or `wrangler deploy`.

The claim relayer stays on Render (`claim-relayer/`, service `bot-verifier-claim-relayer`). Wallet UX is a static Vite app. Escrow submits go out through the connected wallet. The relayer is not a Pages or Workers app.

## Project settings

Set these in the Cloudflare dashboard when the project is created. [`wrangler.toml`](wrangler.toml) records the project name and the build output directory. Git root, build command, and production branch are dashboard fields.

| Setting | Value |
| --- | --- |
| Project name | `agent-a-wallet-ux` |
| Production branch | `main` |
| Root directory | `apps/wallet-ux` |
| Build command | `npm ci && npm run build` |
| Build output directory | `dist` |
| Node.js | `22.16.0` (`.node-version` in this directory; Pages v3 default; CI uses Node 22) |

`pages_build_output_dir = "./dist"` matches the Vite `dist` output. Once the Pages project uses this Wrangler file, that output directory is the source of truth. Leave the framework preset unset so it does not replace the build command.

## Environment variables

Set variables for **Production** and **Preview**. Vite inlines `VITE_*` during `npm run build`, so a Pages variable has to be present for the build, not only in the browser afterward.

| Variable | Required | Value |
| --- | --- | --- |
| `SKIP_DEPENDENCY_INSTALL` | Yes | `1`. Stops Pages from running its own `npm install` before the build command. `npm ci` is the install. |
| `VITE_BASE_SEPOLIA_RPC_URL` | No | Base Sepolia HTTP endpoint. Leave unset to use `https://sepolia.base.org`. The app calls `eth_chainId` and accepts only `84532`. |
| `NODE_VERSION` | No | Optional override. `.node-version` already pins `22.16.0`. |

The default public RPC needs no secret. If a custom URL contains an API key, store `VITE_BASE_SEPOLIA_RPC_URL` as an encrypted build variable. Pages has no wallet private key, relayer key, `LIVE_SUBMIT`, or `SPENCER_RUN_AUTH`.

`BASE_SEPOLIA_RPC_URL` at the repo root is for Foundry and the claim relayer. This app does not read it.

## Address book

`npm run dev`, `npm test`, and `npm run build` copy [`deployments/base-sepolia.json`](../../deployments/base-sepolia.json) to `src/generated/base-sepolia.json` before Vite starts. That file is gitignored. Vite imports it from inside `apps/wallet-ux`. Pages checks out the whole Git repository and runs the build in that root directory, so the script can still read the canonical book one level above the app. The copy script refuses a book whose `chainId` is not `84532` or whose `network` is not `base-sepolia`.

`src/book.ts` `FALLBACK_PIN` matches the live book. The app uses the pin only when the copied JSON is missing or fails validation. Superseded Denylist and Vault addresses stay blocked.

Live slots:

| Contract | Address |
| --- | --- |
| coreTimelock | `0x10CC9474b45625ADfd05C209f2518023484878D9` |
| Denylist | `0xeE76876bECcFc1B58fC06fF4E654a517d784B224` |
| Vault | `0x1463D664fA467FBCDA4B05443434494f05e565bc` |
| DisputePanel | `0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb` |
| BotAttestationEscrow | `0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c` |

## Go-live checklist

1. Create a Pages project named `agent-a-wallet-ux` connected to `SAW72/AGENT-A`.
2. Production branch: `main`.
3. Root directory: `apps/wallet-ux`.
4. Build command: `npm ci && npm run build`.
5. Output directory: `dist` (also `pages_build_output_dir` in `wrangler.toml`).
6. Build image v3, Node `22.16.0` from `.node-version`.
7. Production and Preview: `SKIP_DEPENDENCY_INSTALL=1`. Leave `VITE_BASE_SEPOLIA_RPC_URL` unset unless the public `https://sepolia.base.org` endpoint should be replaced with another Base Sepolia URL (`eth_chainId` `84532`).
8. Secrets: none for the public RPC. No private keys and no relayer unlock flags.
9. Hostname: `agent-a-wallet-ux.pages.dev` until a custom domain is added in the dashboard (DNS plus the Pages custom domain). This repo does not attach a domain.
10. Build log includes `Copied deployments/base-sepolia.json -> src/generated/base-sepolia.json (chainId 84532)`. The published app stays on Base Sepolia.
11. Leave claim-relayer on Render (`bot-verifier-claim-relayer`).

Optional build watch paths: `apps/wallet-ux/**` and `deployments/base-sepolia.json`. A watch list that omits the deployment book will skip a publish when only addresses change.

## Local check

```bash
cd apps/wallet-ux
npm ci
npm test
npm run build
```

`dist/` is the directory Pages publishes. It is gitignored.
