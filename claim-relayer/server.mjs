import { pathToFileURL } from "node:url";
import { createClaimRelayer } from "./app.mjs";
import { createSepoliaBroadcaster } from "./broadcast.mjs";
import { loadConfig } from "./config.mjs";
import { createClaimLog } from "./claimLog.mjs";
import { createKillSwitch } from "./killSwitch.mjs";
import { createNonceStore } from "./nonceStore.mjs";

/**
 * Process entry. The relayer key is passed into the broadcaster only when live
 * submit is allowed. It is not logged. Fixture mode does not read it.
 */
export function startServer(env = process.env) {
  const config = loadConfig(env);
  const killSwitch = createKillSwitch({ initial: config.killSwitchInitial });
  const nonceStore = createNonceStore();
  const claimLog = createClaimLog({ filePath: config.claimLogPath });
  const broadcaster = config.liveSubmit.allowed
    ? createSepoliaBroadcaster({
        rpcUrl: env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org",
        privateKey: env.RELAYER_PRIVATE_KEY,
      })
    : null;
  const server = createClaimRelayer({ config, killSwitch, nonceStore, claimLog, broadcaster });
  const mode = config.liveSubmit.allowed ? "live" : "fixture";
  server.listen(config.port, config.host, () => {
    console.log(
      `claim-relayer listening on ${config.host}:${config.port} mode=${mode} chainId=${config.chainId} escrowBooked=${config.escrowBooked} killSwitch=${killSwitch.isOn()} liveSubmit=${config.liveSubmit.allowed}`,
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
