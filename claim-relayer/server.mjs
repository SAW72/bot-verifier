import { pathToFileURL } from "node:url";
import { createClaimRelayer } from "./app.mjs";
import { loadConfig } from "./config.mjs";
import { createClaimLog } from "./claimLog.mjs";
import { createKillSwitch } from "./killSwitch.mjs";
import { createNonceStore } from "./nonceStore.mjs";

/**
 * Process entry. RELAYER_PRIVATE_KEY is never read. No wallet, no RPC, no broadcast.
 */
export function startServer(env = process.env) {
  const config = loadConfig(env);
  const killSwitch = createKillSwitch({ initial: config.killSwitchInitial });
  const nonceStore = createNonceStore();
  const claimLog = createClaimLog({ filePath: config.claimLogPath });
  const server = createClaimRelayer({ config, killSwitch, nonceStore, claimLog });
  server.listen(config.port, config.host, () => {
    console.log(
      `claim-relayer listening on ${config.host}:${config.port} mode=fixture chainId=${config.chainId} escrowBooked=${config.escrowBooked} killSwitch=${killSwitch.isOn()} liveSubmit=false`,
    );
  });
  return server;
}

const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  try {
    startServer();
  } catch (err) {
    console.error(err.error || err.message || "claim_relayer_config_error");
    process.exit(1);
  }
}
