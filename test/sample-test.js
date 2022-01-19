const { expect } = require("chai");
const { ethers } = require("hardhat");
const crypto         = require('crypto');
const ecPem          = require('ec-pem');
const ethereumJSUtil = require('ethereumjs-util');

async function setupNZCP() {
  const NZCP = await ethers.getContractFactory("NZCP");
  const nzcp = await NZCP.deploy();
  await nzcp.deployed();
  return nzcp
}

async function setupEC() {
  const EC = await ethers.getContractFactory("EllipticCurve");
  const ec = await EC.deploy();
  await ec.deployed();
  return ec
}


const EXAMPLE_X = "0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD";
const EXAMPLE_Y = "0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D";
const LIVE_X = "0x0D008A26EB2A32C4F4BBB0A3A66863546907967DC0DDF4BE6B2787E0DBB9DAD7";
const LIVE_Y = "0x971816CEC2ED548F1FA999933CFA3D9D9FA4CC6B3BC3B5CEF3EAD453AF0EC662";

describe("NZCP", function () {
  it("Should verify signature with EC", async function () {

    const ec = await setupEC()
    // Create contract.
    // curve = await SECP256R1.new();

    // Create curve object for key and signature generation.
    var prime256v1 = crypto.createECDH('prime256v1');
    prime256v1.generateKeys();

    // Reformat keys.
    var pemFormattedKeyPair = ecPem(prime256v1, 'prime256v1');
    const publicKey = [
      '0x' + prime256v1.getPublicKey('hex').slice(2, 66),
      '0x' + prime256v1.getPublicKey('hex').slice(-64)
    ];

    // Create random message and sha256-hash it.
    var message = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 5);
    console.log('Message: ' + message);
    const messageHash = ethereumJSUtil.bufferToHex(ethereumJSUtil.sha256(Buffer.from(message)));

    // Create signature.
    var signer = crypto.createSign('RSA-SHA256');
    signer.update(message);
    var sigString = signer.sign(pemFormattedKeyPair.encodePrivateKey(), 'hex');

    // Reformat signature / extract coordinates.
    var xlength = 2 * ('0x' + sigString.slice(6, 8));
    var sigString = sigString.slice(8)
    const signature = [
      '0x' + sigString.slice(0, xlength),
      '0x' + sigString.slice(xlength + 4)
    ];


    expect(await ec.validateSignature(messageHash, signature, publicKey)).to.equal(true);

  })

  it("Should verify signature with NZCP example pubkey", async function () {
    const ec = await setupEC()
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    expect(await ec.validateSignature(messageHash, [r, s], [EXAMPLE_X, EXAMPLE_Y])).to.equal(true);
  })



  it("Should verify signature with NZCP example pubkey via nzcp", async function () {
    const nzcp = await setupNZCP()
    // Jack Sparrow example pass
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    expect(await nzcp.verifySignature(messageHash, [r, s], 1)).to.equal(true);

  })


  it("Should verify signature with ToBeSignedBuffer", async function () {

    const nzcp = await setupNZCP()
    // Jack Sparrow example pass
    const toBeSignedBuffer = "0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D3136075060A4F54D4E304332BE33AD78B1EAFA4B"
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";

    expect(await nzcp.verifyToBeSignedBuffer(toBeSignedBuffer, [r, s], 1)).to.equal(true);

  });

  it("Should parse credential subject in ToBeSignedBuffer", async function () {

    const nzcp = await setupNZCP()
    // Jack Sparrow example pass
    const toBeSignedBuffer = "0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D3136075060A4F54D4E304332BE33AD78B1EAFA4B"
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";

    const result = await nzcp.parseAndVerifyToBeSignedBuffer(toBeSignedBuffer, [r, s], 1)
    const john = ["Jack", "Sparrow", "1960-04-16"];
    expect(result).to.deep.equal(john);

  });
});
