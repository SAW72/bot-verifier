import { expect } from "chai";
import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("BotAttestationEscrow", function () {
  let denylist: any, vault: any, escrow: any;
  let owner: any, payer: any, payee: any;
  const payerBot = ethers.id("payer-bot");
  const payeeBot = ethers.id("payee-bot");

  beforeEach(async function () {
    [owner, payer, payee] = await ethers.getSigners();
    const Denylist = await ethers.getContractFactory("Denylist");
    denylist = await Denylist.deploy();
    const Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.deploy(await denylist.getAddress());
    const Escrow = await ethers.getContractFactory("BotAttestationEscrow");
    escrow = await Escrow.deploy(await denylist.getAddress(), await vault.getAddress());

    // Register both bots at Financial tier.
    await vault
      .connect(owner)
      .register(payerBot, ethers.id("w1"), ethers.id("b1"), ethers.id("p1"), 3);
    await vault
      .connect(owner)
      .register(payeeBot, ethers.id("w2"), ethers.id("b2"), ethers.id("p2"), 3);
  });

  it("creates an escrow and releases after mutual attestation", async function () {
    const escrowId = ethers.id("deal-1");
    const amount = ethers.parseEther("1");
    await escrow
      .connect(payer)
      .createEscrow(escrowId, payee.address, payerBot, payeeBot, 3600, { value: amount });

    await expect(escrow.connect(payer).release(escrowId))
      .to.changeEtherBalance(payee, amount);
  });

  it("refunds the payer when the escrow expires", async function () {
    const escrowId = ethers.id("deal-2");
    const amount = ethers.parseEther("1");
    await escrow
      .connect(payer)
      .createEscrow(escrowId, payee.address, payerBot, payeeBot, 100, { value: amount });

    await time.increase(101);
    await expect(escrow.connect(payer).refund(escrowId)).to.changeEtherBalance(
      payer,
      amount
    );
  });

  it("blocks release when a bot is denylisted", async function () {
    await denylist.connect(owner).addExact(ethers.id("w2"));
    const escrowId = ethers.id("deal-3");
    await escrow
      .connect(payer)
      .createEscrow(escrowId, payee.address, payerBot, payeeBot, 3600, {
        value: ethers.parseEther("1"),
      });
    await expect(escrow.connect(payer).release(escrowId)).to.be.revertedWithCustomError(
      escrow,
      "AttestationFailed"
    );
  });

  it("rejects replay of the same escrow id", async function () {
    const escrowId = ethers.id("deal-4");
    await escrow
      .connect(payer)
      .createEscrow(escrowId, payee.address, payerBot, payeeBot, 3600, {
        value: ethers.parseEther("1"),
      });
    await expect(
      escrow
        .connect(payer)
        .createEscrow(escrowId, payee.address, payerBot, payeeBot, 3600, {
          value: ethers.parseEther("1"),
        })
    ).to.be.revertedWithCustomError(escrow, "Replay");
  });
});
