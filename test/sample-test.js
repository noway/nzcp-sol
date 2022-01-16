const { expect } = require("chai");
const { ethers } = require("hardhat");

async function setupGreeter() {
  const NZCP = await ethers.getContractFactory("NZCP");
  const greeter = await NZCP.deploy("Hello, world!");
  await greeter.deployed();
  return greeter
}

describe("NZCP", function () {
  it("Should return the new greeting once it's changed", async function () {

    const greeter = await setupGreeter()
    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
  it("Should verify greeting", async function () {
    const greeter = await setupGreeter()

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.verifyGreeting("Hola, mundo!")).to.equal(true);
  });

  it("Should verify signature 1", async function () {
    const greeter = await setupGreeter()
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    const v = 0x77;
    expect(await greeter.verifySignature(messageHash, r, s, v)).to.equal(true);

  })
  it("Should verify signature 2", async function () {
    const greeter = await setupGreeter()
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    const s = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const v = 0x54;
    expect(await greeter.verifySignature(messageHash, r, s, v)).to.equal(true);

  })
});
