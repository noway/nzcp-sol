const { expect } = require("chai");
const { ethers } = require("hardhat");

async function setupNZCP() {
  const NZCP = await ethers.getContractFactory("NZCP");
  const nzcp = await NZCP.deploy("Hello, world!");
  await nzcp.deployed();
  return nzcp
}

describe("NZCP", function () {
  it("Should return the new greeting once it's changed", async function () {

    const nzcp = await setupNZCP()
    expect(await nzcp.greet()).to.equal("Hello, world!");

    const setGreetingTx = await nzcp.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await nzcp.greet()).to.equal("Hola, mundo!");
  });
  it("Should verify greeting", async function () {
    const nzcp = await setupNZCP()

    const setGreetingTx = await nzcp.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await nzcp.verifyGreeting("Hola, mundo!")).to.equal(true);
  });

  it("Should verify signature 1", async function () {
    const nzcp = await setupNZCP()
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    const v = 0x77;
    expect(await nzcp.verifySignature(messageHash, r, s, v)).to.equal(true);

  })
  it("Should verify signature 2", async function () {
    const nzcp = await setupNZCP()
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    const s = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const v = 0x54;
    expect(await nzcp.verifySignature(messageHash, r, s, v)).to.equal(true);

  })
});
