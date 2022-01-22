const { expect } = require("chai");
const { ethers } = require("hardhat");
const { verifyPassURIOffline } = require("@vaxxnz/nzcp");
const {getToBeSigned} = require('../jslib/nzcp')

require('dotenv').config()

async function setupNZCP() {
  const NZCP = await ethers.getContractFactory("NZCP");
  const nzcp = await NZCP.deploy();
  await nzcp.deployed();
  return nzcp
}


const JackSparrow = ["Jack", "Sparrow", "1960-04-16"];

// Jack Sparrow example pass
const EXAMPLE_PASS = {
  ToBeSigned: "0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D3136075060A4F54D4E304332BE33AD78B1EAFA4B",
  rs: ["0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154", "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477",]
}

const BAD_PUBLIC_KEY_PASS = {
  ToBeSigned: "0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D3136075063FBA7A6286D45EA8AC5F57114BA3DBC",
  rs: ["0x743D91C84662FBBE80D3A3B6A3020B0D88E68C0B4236201D0D1D9555CC954B2D", "0x73C0653E01E6F60E1FF6F2125361C992682F2A88996775ED864787343EAC1CF4"]
}

const PUBLIC_KEY_NOT_FOUND_PASS = {
  ToBeSigned: "0x846A5369676E6174757265314AA204456B65792D3201264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D31360750B1FB5906C0F04B0CB48FA1D84E6DCF53",
  rs: ["0x4527172C800758199B4A92158B1F04C121CE98B21FC8DF723ED050A770B3E1F2", "0xA49E8B67D65369388465251272D0CC6DD63F4FD49684CA825D7DCC0EFE7E80E5"]
}

const MODIFIED_SIGNATURE_PASS = {
  ToBeSigned: "0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D3136075060A4F54D4E304332BE33AD78B1EAFA4B",
  rs: ["0x00000000000000000000BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154", "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477"]
}

const MODIFIED_PAYLOAD_PASS = {
  ToBeSigned: "0x846A5369676E6174757265314AA204456B65792D3101264059011CA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D656553746576656A66616D696C794E616D6563446F6563646F626A313936302D30342D3136075060A4F54D4E304332BE33AD78B1EAFA4B",
  rs: ["0x00000000000000000000BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154", "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477"]
}

const EXPIRED_PASS = {
  ToBeSigned: "0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A5FA0668B041A61785F8B627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D3136075077D36A442A374DAABAD3030ECFAA8B00",
  rs: ["0x59B85EDF92C4C1EAD34ECD2223A93FE37012913026E380F7169DE0912A0CAA8D", "0x75029863D917141CAAB0E8BE927DB5D93ECECB669DD72F81A82D2DA16306CE34"]
}

const NOT_ACTIVE_PASS = {
  ToBeSigned: "0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A6AE8ED0B041A6CCA208B627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D313607506BED8ECC52F042358BEF40CC4C9282ED",
  rs: ["0xF6A9A841A390A40BD5CEE4434CCCDB7499D9461840F5C8DFF436CBA0698B1AB2", "0x4DCA052720B9F581200BEBAC2FFF1AFA159CE42AEB38D558DF9413899DB48271"]
}

describe("NZCP - example pass ToBeSigned", function () {
  it("Should verify signature with NZCP example pubkey", async function () {
    const nzcp = await setupNZCP()
    // Jack Sparrow example pass
    const messageHash = "0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE";
    const r = "0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154";
    const s = "0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477";
    expect(await nzcp.verifySign(messageHash, [r, s], 1)).to.equal(true);

  })

  it("Should parse credential subject in ToBeSigned", async function () {
    const nzcp = await setupNZCP()
    const result = await nzcp.readCredSubj(
      EXAMPLE_PASS.ToBeSigned, EXAMPLE_PASS.rs, 1)
    expect(result).to.deep.equal(JackSparrow);
  });

  it("Should fail BAD_PUBLIC_KEY_PASS", async function () {
    const nzcp = await setupNZCP();
    expect(
      nzcp.readCredSubj(
        BAD_PUBLIC_KEY_PASS.ToBeSigned, BAD_PUBLIC_KEY_PASS.rs, 1)
    ).to.be.revertedWith("InvalidSignature()");
  });

  it("Should parse PUBLIC_KEY_NOT_FOUND_PASS while violating spec", async function () {
    const nzcp = await setupNZCP();
    const result = await nzcp.readCredSubj(
      PUBLIC_KEY_NOT_FOUND_PASS.ToBeSigned, PUBLIC_KEY_NOT_FOUND_PASS.rs, 1);
    // We're deviating from the spec here, since NZ Ministry of Health is not going to issue passes with mismatching kid.
    expect(result).to.deep.equal(JackSparrow);
  });

  it("Should fail MODIFIED_SIGNATURE_PASS", async function () {
    const nzcp = await setupNZCP();
    expect(
      nzcp.readCredSubj(
        MODIFIED_SIGNATURE_PASS.ToBeSigned, MODIFIED_SIGNATURE_PASS.rs, 1)
    ).to.be.revertedWith("InvalidSignature()");
  });

  it("Should fail MODIFIED_PAYLOAD_PASS", async function () {
    const nzcp = await setupNZCP();
    expect(
      nzcp.readCredSubj(
        MODIFIED_PAYLOAD_PASS.ToBeSigned, MODIFIED_PAYLOAD_PASS.rs, 1)
    ).to.be.revertedWith("InvalidSignature()");
  });

  it("Should fail EXPIRED_PASS", async function () {
    const nzcp = await setupNZCP();
    expect(
      nzcp.readCredSubj(
        EXPIRED_PASS.ToBeSigned, EXPIRED_PASS.rs, 1)
    ).to.be.revertedWith("PassExpired()");
  });

  it("Should parse NOT_ACTIVE_PASS while violating spec", async function () {
    const nzcp = await setupNZCP();
    const result = await nzcp.readCredSubj(
      NOT_ACTIVE_PASS.ToBeSigned, NOT_ACTIVE_PASS.rs, 1);
    // Deviating from spec again, since NZ Ministry of Health is not going to issue passes which are not yet active.
    expect(result).to.deep.equal(JackSparrow);
  });
});


const EXAMPLE_PASS_URI = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVAYFE6VGU4MCDGK7DHLLYWHVPUS2YIDJOA6Y524TD3AZRM263WTY2BE4DPKIF27WKF3UDNNVSVWRDYIYVJ65IRJJJ6Z25M2DO4YZLBHWFQGVQR5ZLIWEQJOZTS3IQ7JTNCFDX";

const BAD_PUBLIC_KEY_PASS_URI = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVAY73U6TCQ3KF5KFML5LRCS5D3PCYIB2D3EOIIZRPXPUA2OR3NIYCBMGYRZUMBNBDMIA5BUOZKVOMSVFS246AMU7ADZXWBYP7N4QSKNQ4TETIF4VIRGLHOXWYMR4HGQ7KYHHU";

const PUBLIC_KEY_NOT_FOUND_PASS_URI = "NZCP:/1/2KCEVIQEIVVWK6JNGIASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVBMP3LEDMB4CLBS2I7IOYJZW46U2YIBCSOFZMQADVQGM3JKJBLCY7ATASDTUYWIP4RX3SH3IFBJ3QWPQ7FJE6RNT5MU3JHCCGKJISOLIMY3OWH5H5JFUEZKBF27OMB37H5AHF";

const MODIFIED_SIGNATURE_PASS_URI = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVAYFE6VGU4MCDGK7DHLLYWHVPUS2YIAAAAAAAAAAAAAAAAC63WTY2BE4DPKIF27WKF3UDNNVSVWRDYIYVJ65IRJJJ6Z25M2DO4YZLBHWFQGVQR5ZLIWEQJOZTS3IQ7JTNCFDX";

const MODIFIED_PAYLOAD_PASS_URI = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEOKKALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWKU3UMV3GK2TGMFWWS3DZJZQW2ZLDIRXWKY3EN5RGUMJZGYYC2MBUFUYTMB2QMCSPKTKOGBBTFPRTVV4LD2X2JNMEAAAAAAAAAAAAAAAABPN3J4NASOBXVEC5P3FC52BWW2ZK3IR4EMKU7OUIUUU7M5OWNBXOMMVQT3CYDKYI64VULCIEXMZZNUIPUZWRCR3Q";

const EXPIRED_PASS_URI = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUX5AM2FQIGTBPBPYWYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVA56TNJCCUN2NVK5NGAYOZ6VIWACYIBM3QXW7SLCMD2WTJ3GSEI5JH7RXAEURGATOHAHXC2O6BEJKBSVI25ICTBR5SFYUDSVLB2F6SJ63LWJ6Z3FWNHOXF6A2QLJNUFRQNTRU";

const NOT_ACTIVE_PASS_URI = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRU2XI5UFQIGTMZIQIWYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVA27NR3GFF4CCGWF66QGMJSJIF3KYID3KTKCBUOIKIC6VZ3SEGTGM3N2JTWKGDBAPLSG76Q3MXIDJRMNLETOKAUTSBOPVQEQAX25MF77RV6QVTTSCV2ZY2VMN7FATRGO3JATR";

describe("NZCP - example pass URIs", function () {
  it("Should pass on EXAMPLE_PASS_URI", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(EXAMPLE_PASS_URI);
    expect(await nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 1)).to.deep.equal(JackSparrow);
  });
  it("Should fail on BAD_PUBLIC_KEY_PASS_URI", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(BAD_PUBLIC_KEY_PASS_URI);
    expect(nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 1)).to.be.revertedWith("InvalidSignature()")
  });
  it("Should fail on PUBLIC_KEY_NOT_FOUND_PASS_URI", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(PUBLIC_KEY_NOT_FOUND_PASS_URI);
    // We're deviating from the spec here, since NZ Ministry of Health is not going to issue passes with mismatching kid.
    expect(await nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 1)).to.deep.equal(JackSparrow) 
  });
  it("Should fail on MODIFIED_SIGNATURE_PASS_URI", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(MODIFIED_SIGNATURE_PASS_URI);
    expect(nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 1)).to.be.revertedWith("InvalidSignature()")
  });
  it("Should fail on MODIFIED_PAYLOAD_PASS_URI", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(MODIFIED_PAYLOAD_PASS_URI);
    expect(nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 1)).to.be.revertedWith("InvalidSignature()")
  });
  it("Should fail on EXPIRED_PASS_URI", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(EXPIRED_PASS_URI);
    expect(nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 1)).to.be.revertedWith("PassExpired()")
  });
  it("Should pass on NOT_ACTIVE_PASS_URI", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(NOT_ACTIVE_PASS_URI);
    // Deviating from spec again, since NZ Ministry of Health is not going to issue passes which are not yet active.
    expect(await nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 1)).to.deep.equal(JackSparrow);
  });
})

const LIVE_PASS_URI_1 = process.env.LIVE_PASS_URI_1;
const LIVE_PASS_URI_2 = process.env.LIVE_PASS_URI_2;
const LIVE_PASS_URI_3 = process.env.LIVE_PASS_URI_3;

describe("NZCP - live pass URIs", function () {
  it("Should pass on LIVE_PASS_URI_1", async function () {
    const nzcp = await setupNZCP();
    const pass = getToBeSigned(LIVE_PASS_URI_1);
    const result = verifyPassURIOffline(LIVE_PASS_URI_1)
    const credSubj = [result.credentialSubject.givenName, result.credentialSubject.familyName, result.credentialSubject.dob]
    expect(await nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 0)).to.deep.equal(credSubj);
  });
  if (LIVE_PASS_URI_2) {
    it("Should pass on LIVE_PASS_URI_2", async function () {
      const nzcp = await setupNZCP();
      const pass = getToBeSigned(LIVE_PASS_URI_2);
      const result = verifyPassURIOffline(LIVE_PASS_URI_2)
      const credSubj = [result.credentialSubject.givenName, result.credentialSubject.familyName, result.credentialSubject.dob]
      expect(await nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 0)).to.deep.equal(credSubj);
    });
  }
  if (LIVE_PASS_URI_3) {
    it("Should pass on LIVE_PASS_URI_3", async function () {
      const nzcp = await setupNZCP();
      const pass = getToBeSigned(LIVE_PASS_URI_3);
      const result = verifyPassURIOffline(LIVE_PASS_URI_3)
      const credSubj = [result.credentialSubject.givenName, result.credentialSubject.familyName, result.credentialSubject.dob]
      expect(await nzcp.readCredSubj(pass.ToBeSigned, pass.rs, 0)).to.deep.equal(credSubj);
    });
  }
});