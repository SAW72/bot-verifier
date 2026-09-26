import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { privateKeyToAccount } from "viem/accounts";
import { assertSepoliaRawTx, createSepoliaBroadcaster } from "../broadcast.mjs";
import { BOOKED_SEPOLIA_ESCROW } from "../config.mjs";

const KEY = "0x" + "11".repeat(32);
const ESCROW_ID = "0x" + "ab".repeat(32);

describe("sepolia broadcaster", () => {
  it("accepts an EIP-1559 payload for chain 84532 and refuses other chain ids", async () => {
    const account = privateKeyToAccount(KEY);
    const signed = await account.signTransaction({
      chainId: 84532,
      nonce: 0,
      gas: 21_000n,
      maxFeePerGas: 100n,
      maxPriorityFeePerGas: 1n,
      to: BOOKED_SEPOLIA_ESCROW,
      value: 0n,
      type: "eip1559",
    });
    assert.equal(assertSepoliaRawTx(signed), undefined);

    const mainnet = await account.signTransaction({
      chainId: 1,
      nonce: 0,
      gas: 21_000n,
      gasPrice: 100n,
      to: BOOKED_SEPOLIA_ESCROW,
      value: 0n,
      type: "legacy",
    });
    assert.throws(() => assertSepoliaRawTx(mainnet), (err) => err.error === "wrong_chain");

    const base = await account.signTransaction({
      chainId: 8453,
      nonce: 0,
      gas: 21_000n,
      maxFeePerGas: 100n,
      maxPriorityFeePerGas: 1n,
      to: BOOKED_SEPOLIA_ESCROW,
      value: 0n,
      type: "eip1559",
    });
    assert.throws(() => assertSepoliaRawTx(base), (err) => err.error === "wrong_chain");
  });

  it("refuses mainnet and the wrong escrow before any RPC", async () => {
    const seen = [];
    const broadcaster = createSepoliaBroadcaster({
      privateKey: KEY,
      request: async ({ method }) => {
        seen.push(method);
        return "0x14a34";
      },
    });
    await assert.rejects(
      () => broadcaster.send({ chainId: 1, to: BOOKED_SEPOLIA_ESCROW, data: "0x1234", valueWei: "0" }),
      (err) => err.error === "mainnet_refused",
    );
    await assert.rejects(
      () => broadcaster.send({ chainId: 8453, to: BOOKED_SEPOLIA_ESCROW, data: "0x1234", valueWei: "0" }),
      (err) => err.error === "mainnet_refused",
    );
    await assert.rejects(
      () =>
        broadcaster.send({
          chainId: 84532,
          to: "0x3333333333333333333333333333333333333333",
          data: "0x1234",
          valueWei: "0",
        }),
      (err) => err.error === "escrow_not_booked_sepolia",
    );
    assert.deepEqual(seen, []);
    assert.equal(JSON.stringify(broadcaster).includes(KEY), false);
  });

  it("stops when the RPC reports mainnet and does not send a raw transaction", async () => {
    const seen = [];
    const broadcaster = createSepoliaBroadcaster({
      privateKey: KEY,
      request: async ({ method }) => {
        seen.push(method);
        if (method === "eth_chainId") return "0x2105";
        throw new Error("should not continue");
      },
    });
    await assert.rejects(
      () => broadcaster.send({ chainId: 84532, to: BOOKED_SEPOLIA_ESCROW, data: "0x1234", valueWei: "0" }),
      (err) => err.error === "mainnet_refused" && err.chainId === 8453,
    );
    assert.deepEqual(seen, ["eth_chainId"]);
  });

  it("signs a release and submits it on the mocked Sepolia RPC", async () => {
    const seen = [];
    let raw = null;
    const broadcaster = createSepoliaBroadcaster({
      privateKey: KEY,
      request: async ({ method, params }) => {
        seen.push(method);
        if (method === "eth_chainId") return "0x14a34";
        if (method === "eth_fillTransaction") throw new Error("eth_fillTransaction is not available");
        if (method === "eth_getTransactionCount") return "0x0";
        if (method === "eth_getBlockByNumber") return sepoliaBlock();
        if (method === "eth_maxPriorityFeePerGas") return "0x59682f00";
        if (method === "eth_gasPrice") return "0x3b9aca00";
        if (method === "eth_estimateGas") return "0x030d40";
        if (method === "eth_call") return "0x";
        if (method === "eth_sendRawTransaction") {
          raw = params[0];
          return "0x" + "cd".repeat(32);
        }
        throw new Error(`unexpected ${method}`);
      },
    });
    const result = await broadcaster.send({
      chainId: 84532,
      to: BOOKED_SEPOLIA_ESCROW,
      data: "0x" + "12".repeat(4) + ESCROW_ID.slice(2),
      valueWei: "0",
    });
    assert.equal(result.txHash, "0x" + "cd".repeat(32));
    assert.equal(seen.includes("eth_sendRawTransaction"), true);
    assert.equal(seen[0], "eth_chainId");
    assertSepoliaRawTx(raw);
    assert.equal(String(raw).toLowerCase().includes(KEY.slice(2)), false);
    assert.equal(JSON.stringify(result).includes(KEY.slice(2)), false);
  });

  it("drops the private key from a broadcast failure", async () => {
    const broadcaster = createSepoliaBroadcaster({
      privateKey: KEY,
      request: async ({ method }) => {
        if (method === "eth_chainId") return "0x14a34";
        throw new Error(`rpc failed ${KEY}`);
      },
    });
    await assert.rejects(
      () => broadcaster.send({ chainId: 84532, to: BOOKED_SEPOLIA_ESCROW, data: "0x", valueWei: "0" }),
      (err) => {
        const blob = JSON.stringify(err);
        return err.error === "broadcast_failed" && !blob.includes(KEY.slice(2)) && !blob.includes(KEY);
      },
    );
  });
});

function sepoliaBlock() {
  return {
    baseFeePerGas: "0x3b9aca00",
    gasLimit: "0x1c9c380",
    gasUsed: "0x0",
    number: "0x1",
    timestamp: "0x65000000",
    hash: "0x" + "11".repeat(32),
    parentHash: "0x" + "22".repeat(32),
    transactions: [],
    miner: "0x" + "33".repeat(20),
    difficulty: "0x0",
    totalDifficulty: "0x0",
    extraData: "0x",
    nonce: "0x0000000000000000",
    size: "0x1",
    stateRoot: "0x" + "44".repeat(32),
  };
}
