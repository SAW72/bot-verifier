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
| Node.js | `22` (`.node-version` in this directory; same major as CI) |

`pages_build_output_dir = "./dist"` matches the Vite `dist` output. Once the Pages project uses this Wrangler file, that output directory is the source of truth. Leave the framework preset unset so it does not replace the build command.

Node 22 on the Pages v3 image is 22.16.0, which satisfies Vite (`>=22.12.0`). `NODE_VERSION=22` is the dashboard form of the same pin.

### SPA

[`public/_redirects`](public/_redirects) is:

```
/* /index.html 200
```

Vite copies that file to `dist/_redirects`. The app is one page today. Keep this rule if client routes are added later so those paths serve `index.html`.

## Environment variables

Set variables for **Production** and **Preview**. Vite inlines `VITE_*` during `npm run build`, so a Pages variable has to be present for the build, not only in the browser afterward.

| Variable | Go-live value |
| --- | --- |
| `VITE_BASE_SEPOLIA_RPC_URL` | Optional. Leave unset to use `https://sepolia.base.org`. Any URL must answer `eth_chainId` with `84532`. |
| `VITE_CLAIM_RELAYER_URL` | Leave unset. The wallet does not call the relayer at go-live. |
| `SKIP_DEPENDENCY_INSTALL` | `1`. Pages would otherwise run its own `npm install` before the build command. `npm ci` is the install. |

Pages must not have `PRIVATE_KEY`, `RELAYER_PRIVATE_KEY`, `SPENCER_RUN_AUTH`, `LIVE_SUBMIT`, or `ADMIN_SECRET`. Those belong to Foundry or the Render claim relayer, not this static app.

`BASE_SEPOLIA_RPC_URL` at the repo root is for Foundry and the claim relayer. This app does not read it.

Later, if the browser calls the Render relayer, that service needs CORS for the Pages origin (`https://agent-a-wallet-ux.pages.dev` or the custom domain). Do not turn that on for this go-live.

## Address book

The app imports [`src/base-sepolia.json`](src/base-sepolia.json). That file is a copy of [`deployments/base-sepolia.json`](../../deployments/base-sepolia.json) committed inside `apps/wallet-ux`. Vite does not import `../../../deployments/base-sepolia.json`, so a Pages root of `apps/wallet-ux` can build when the parent directory is not on the build path.

`npm run dev` and `npm run build` run `scripts/sync-book.mjs`. When the repo-root book is visible, the script refreshes `src/base-sepolia.json`. When it is not visible, the script keeps the committed copy. Either way the book must be Base Sepolia (`chainId` 84532, `network` `base-sepolia`). After a book change in the full repo, run `npm run sync-book` and commit `src/base-sepolia.json`. `npm test` fails if the two files differ.

`src/book.ts` `FALLBACK_PIN` matches the live book. The app uses the pin only when the copied JSON fails validation. Superseded Denylist and Vault addresses stay blocked.

Live slots:

| Contract | Address |
| --- | --- |
| coreTimelock | `0x10CC9474b45625ADfd05C209f2518023484878D9` |
| Denylist | `0xeE76876bECcFc1B58fC06fF4E654a517d784B224` |
| Vault | `0x1463D664fA467FBCDA4B05443434494f05e565bc` |
| DisputePanel | `0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb` |
| BotAttestationEscrow | `0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c` |

## Go-live checklist

1. Create a Pages project named `agent-a-wallet-ux` connected to `SAW72/AGENT-A`. Create it only on Spencer GO.
2. Production branch: `main`.
3. Root directory: `apps/wallet-ux`.
4. Build command: `npm ci && npm run build`.
5. Output directory: `dist` (also `pages_build_output_dir` in `wrangler.toml`).
6. Node `22` (`.node-version` or `NODE_VERSION=22`).
7. SPA: `/* /index.html 200` is already in `public/_redirects` for routes added later.
8. Env: optional `VITE_BASE_SEPOLIA_RPC_URL` only (default `https://sepolia.base.org`, chain id `84532`). Leave `VITE_CLAIM_RELAYER_URL` unset. Set `SKIP_DEPENDENCY_INSTALL=1`.
9. Do not set `PRIVATE_KEY`, `RELAYER_PRIVATE_KEY`, `SPENCER_RUN_AUTH`, `LIVE_SUBMIT`, or `ADMIN_SECRET` on Pages.
10. Hostname: `agent-a-wallet-ux.pages.dev` until a custom domain is added in the dashboard. This repo does not attach a domain.
11. Leave claim-relayer on Render (`bot-verifier-claim-relayer`). Add CORS on that service later if the wallet starts calling it.

Optional build watch paths: `apps/wallet-ux/**` and `deployments/base-sepolia.json`. A watch list that omits the deployment book will skip a publish when only the canonical addresses change, until `src/base-sepolia.json` is updated in this directory.

## Local check

```bash
cd apps/wallet-ux
npm ci
npm test
npm run build
```

`dist/` is the directory Pages publishes. It is gitignored.
