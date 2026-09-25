import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFile } from "node:fs/promises";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DEFAULT_RELAYER_ADDRESS, liveSubmitStatus, loadConfig } from "../config.mjs";

const SECRET = "0x" + "ab".repeat(32);

describe("config gates", () => {
  it("defaults to Base Sepolia fixtures and the public hot wallet", () => {
    const config = loadConfig({ RELAYER_PRIVATE_KEY: SECRET });
    assert.equal(config.chainId, 84532);
    assert.equal(config.relayerAddress, DEFAULT_RELAYER_ADDRESS);
    assert.equal(config.escrowBooked, true);
    assert.equal(config.escrowSource, "address_book");
    assert.equal(config.escrowAddress, "0x141214F04b0E1d949B6e6bf32D019Ad7Ab5B284c");
    assert.equal(config.disputePanelAddress, "0x31a92f9A25396968E14d2b55B6B0BB1482ECf1Bb");
    assert.equal(config.coreTimelock, "0x10CC9474b45625ADfd05C209f2518023484878D9");
    assert.equal(config.bvtAddress, null);
    assert.equal(config.liveSubmit.allowed, false);
    assert.ok(config.liveSubmit.blockers.includes("escrow_booked"));
    assert.ok(config.liveSubmit.blockers.includes("spencer_run_auth_required"));
    assert.ok(config.liveSubmit.blockers.includes("scaffold_never_broadcasts"));
    assert.equal(JSON.stringify(config).includes(SECRET), false);
    assert.equal(Object.hasOwn(config, "RELAYER_PRIVATE_KEY"), false);
  });

  it("treats a zero escrow address as unbooked and a real one as booked", () => {
    const zero = loadConfig({ ESCROW_ADDRESS: "0x0000000000000000000000000000000000000000" });
    assert.equal(zero.escrowBooked, false);
    const booked = loadConfig({
      ESCROW_ADDRESS: "0x1111111111111111111111111111111111111111",
      LIVE_SUBMIT: "1",
      SPENCER_RUN_AUTH: "1",
    });
    assert.equal(booked.escrowBooked, true);
    assert.equal(booked.escrowSource, "env");
    assert.equal(booked.liveSubmit.allowed, false);
    assert.equal(booked.liveSubmit.requested, true);
    assert.equal(booked.liveSubmit.spencerAuth, true);
    assert.ok(booked.liveSubmit.blockers.includes("scaffold_never_broadcasts"));
    assert.ok(booked.liveSubmit.blockers.includes("escrow_booked"));
    assert.equal(booked.liveSubmit.blockers.includes("spencer_run_auth_required"), false);
  });

  it("refuses a mainnet address book", async () => {
    const dir = await mkdtemp(join(tmpdir(), "book-"));
    const filePath = join(dir, "book.json");
    await writeFile(filePath, JSON.stringify({ chainId: 8453, network: "base", BotAttestationEscrow: { address: null } }));
    assert.equal(loadConfigThrows({ ADDRESS_BOOK_PATH: filePath }), "mainnet_refused");
  });

  it("refuses mainnet and every other chain", () => {
    assert.equal(loadConfigThrows({ CHAIN_ID: "1" }), "mainnet_refused");
    assert.equal(loadConfigThrows({ CHAIN_ID: "8453" }), "mainnet_refused");
    assert.equal(loadConfigThrows({ CHAIN_ID: "11155111" }), "wrong_chain");
    assert.equal(loadConfigThrows({ CHAIN_ID: "421614" }), "wrong_chain");
  });

  it("refuses a key file env", () => {
    assert.equal(loadConfigThrows({ RELAYER_PRIVATE_KEY_FILE: "/tmp/key" }), "key_file_forbidden");
  });

  it("keeps live submit blocked even when every env gate is on", () => {
    const status = liveSubmitStatus({ LIVE_SUBMIT: "1", SPENCER_RUN_AUTH: "1" }, true);
    assert.equal(status.allowed, false);
    assert.equal(status.error, "live_submit_blocked");
  });

  it("does not call a transaction sender anywhere in the service", async () => {
    const files = [
      "app.mjs",
      "server.mjs",
      "claims.mjs",
      "config.mjs",
      "retry.mjs",
      "escrowCalldata.mjs",
      "addressBook.mjs",
      "readonlyEscrow.mjs",
    ];
    for (const name of files) {
      const text = await readFile(new URL(`../${name}`, import.meta.url), "utf8");
      assert.equal(/writeContract|sendTransaction|eth_sendRawTransaction|signTransaction|forge script/.test(text), false, name);
      assert.equal(text.includes(SECRET), false, name);
    }
  });
});

function loadConfigThrows(env) {
  try {
    loadConfig(env);
  } catch (err) {
    return err.error;
  }
  assert.fail("expected loadConfig to throw");
}
