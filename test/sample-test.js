const { expect } = require("chai");
const { ethers } = require("hardhat");

async function setupNZCP() {
  const NZCP = await ethers.getContractFactory("NZCP");
  const nzcp = await NZCP.deploy("Hello, world!");
  await nzcp.deployed();
  return nzcp
}

async function setupEC() {
  const EC = await ethers.getContractFactory("EllipticCurve");
  const ec = await EC.deploy();
  await ec.deployed();
  return ec
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
  it("Should verify signature with EC", async function () {
    const ec = await setupEC()
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    const x = "0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD";
    const y = "0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D";
    expect(await ec.validateSignature(messageHash, [r, s], [x, y])).to.equal(true);

  })

});
