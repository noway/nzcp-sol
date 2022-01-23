# NZCP.sol

## Features
- Verifies NZCP pass and returns the credential subject (`givenName`, `familyName`, `dob`)
- Reverts transaction if pass is invalid.
- To save gas, the full pass URI is not passed into the contract, but merely the `ToBeSigned` value.
   * `ToBeSigned` value is enough to cryptographically prove that the pass is valid.
   * The definition of `ToBeSigned` can be found here: https://datatracker.ietf.org/doc/html/rfc8152#section-4.4 

## Assumptions
- NZ Ministry of Health never going to sign any malformed CBOR
    * This assumption relies on internal implementation of https://mycovidrecord.nz
 - NZ Ministry of Health never going to sign any pass that is not active
    * This assumption relies on internal implementation of https://mycovidrecord.nz
 - NZ Ministry of Health never going to change the private-public key pair used to sign the pass
    * This assumption relies on trusting NZ Ministry of Health not to leak their private key

## Privacy implications
When you call `NZCP.readCredSubj` function as part of a transaction, your pass gets stored on blockchain as calldata. This allows 3rd parties to read your COVID pass and reconstruct your NZCP QR code. This is bad since your pass could be then used by anyone. Never verify live passes as part of a transaction on a deployed version of this contract.

## Usage
- Prepare `ToBeSigned` value and the `rs` array by calling `getToBeSignedAndRs` from `jslib/nzcp.js` on your pass
- Call either `nzcp.readCredSubjExample(ToBeSigned, rs)` or `nzcp.readCredSubjLive(ToBeSigned, rs)` to verify your pass and get the credential subject

## Requirements 
- [Install Hardhat](https://hardhat.org/getting-started/)

## Building
- Run `make` to build the project
- You can build without live pass verification or without example pass verification by supplying `DFLAGS` environment variable into the `make` command.
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
  - Please don't deploy live pass verification to any remote network, as because executing the verify function as part of a transaction will result in the pass getting stored as calldata on the blockchain and effectively being public.

## Gas Usage
Running tests consumes 1429033 gas units (optimizer enabled, 1000 runs)


## Audits
N/A