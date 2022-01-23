# NZCP.sol

An implementation of the [NZ COVID Pass](https://github.com/minhealthnz/nzcovidpass-spec) spec in Solidity.

## Features
- Verifies NZCP pass and returns the credential subject (`givenName`, `familyName`, `dob`)
- Reverts transaction if pass is invalid.
- To save gas, the full pass URI is not passed into the contract, but merely the `ToBeSigned` value.
   * `ToBeSigned` value is enough to cryptographically prove that the pass is valid.
   * The definition of `ToBeSigned` can be found here: https://datatracker.ietf.org/doc/html/rfc8152#section-4.4 

## Assumptions
- The NZ Ministry of Health is never going to sign any malformed CBOR
    * This assumption relies on internal implementation of https://mycovidrecord.nz
 - The NZ Ministry of Health is never going to sign any pass that is not active
    * This assumption relies on internal implementation of https://mycovidrecord.nz
 - The NZ Ministry of Health is never going to change the private-public key pair used to sign the pass
    * This assumption relies on trusting NZ Ministry of Health not to leak their private key

## Privacy implications
When you call `NZCP.readCredSubjExample` or `NZCP.readCredSubjLive` function as part of a transaction, your pass gets stored on blockchain as calldata. This allows 3rd parties to read your COVID pass and reconstruct your NZCP QR code, **effectively making your pass public**. This is bad since your pass could be then used by anyone. Never verify live passes as part of a transaction on a deployed version of this contract.

Contrary to using `NZCP.readCredSubjExample` or `NZCP.readCredSubjLive` function as part of a transaction, using it as merely a view function (e.g. when calling it via "Read Contract" feature on Etherscan) is fine since execution of a view function happens off-chain.

Please note that the limitations above make any practical use of this contract on live passes to be dangerous.

## Usage
- Prepare `ToBeSigned` value and the `rs` array by calling `getToBeSignedAndRs` from `jslib/nzcp.js` on your pass
- Call either `nzcp.readCredSubjExample(ToBeSigned, rs)` or `nzcp.readCredSubjLive(ToBeSigned, rs)` to verify your pass and get the credential subject

## Requirements 
- [Install Hardhat](https://hardhat.org/getting-started/)

## Building
- Run `make` to build the project
- You can build without the live pass verification or without the example pass verification by supplying `DFLAGS` environment variable into the `make` command.
    - `make DFLAGS=-DEXPORT_EXAMPLE_FUNCS` to build only example pass verification
    - `make DFLAGS=-DEXPORT_LIVE_FUNCS` to build only live pass verification

## Tests
- Create `.env` file in the root directory of the project
- Populate it with at least 1 live pass URI. 
    - Use `.env.example` as a reference.
- Run `make test`

## Deploying
- Populate `.env` with `ALCHEMY_API_KEY` and `ROPSTEN_PRIVATE_KEY`
- Run `make deploy DFLAGS=-DEXPORT_EXAMPLE_FUNCS NETWORK=hardhat` to test deploying
- Run `make deploy DFLAGS=-DEXPORT_EXAMPLE_FUNCS NETWORK=ropsten` to deploy on Ropsten testnet
  - **WARNING**: Please don't deploy live pass verification to any remote network, as because executing the verify function as part of a transaction will result in the pass getting stored as calldata on the blockchain and effectively being public.

## Gas Usage
Running tests consumes 1429033 gas units (optimizer enabled, 1000 runs)

## Deployed version of the contract
Ropsten testnet: https://ropsten.etherscan.io/address/0x14ffb19a685bb8ec4b925604280f7e441a343af9
- Test `readCredSubjExample` with the arguments:
  - `ToBeSigned`: `0x846A5369676E6174757265314AA204456B65792D3101264059011FA501781E6469643A7765623A6E7A63702E636F76696431392E6865616C74682E6E7A051A61819A0A041A7450400A627663A46840636F6E7465787482782668747470733A2F2F7777772E77332E6F72672F323031382F63726564656E7469616C732F7631782A68747470733A2F2F6E7A63702E636F76696431392E6865616C74682E6E7A2F636F6E74657874732F76316776657273696F6E65312E302E306474797065827456657269666961626C6543726564656E7469616C6F5075626C6963436F766964506173737163726564656E7469616C5375626A656374A369676976656E4E616D65644A61636B6A66616D696C794E616D656753706172726F7763646F626A313936302D30342D3136075060A4F54D4E304332BE33AD78B1EAFA4B`
  - `rs`: `[0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154,0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477]`

![image](https://user-images.githubusercontent.com/2031472/150664207-b91d86d5-bb7d-42a2-b6c7-810851e7d266.png)

- Test `verifySignExample` with the arguments:
  - `messageHash`: `0x271CE33D671A2D3B816D788135F4343E14BC66802F8CD841FAAC939E8C11F3EE`
  - `rs`: `[0xD2E07B1DD7263D833166BDBB4F1A093837A905D7ECA2EE836B6B2ADA23C23154,0xFBA88A529F675D6686EE632B09EC581AB08F72B458904BB3396D10FA66D11477]`

![image](https://user-images.githubusercontent.com/2031472/150664215-7fc88844-8026-46cc-ade3-26e90dc02b3a.png)


## Audits
N/A
