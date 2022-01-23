# NZCP.sol

## Features
TODO

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

## Privacy implications
When you call `NZCP.readCredSubj` function as part of a transaction, your pass gets stored on blockchain as calldata. This allows 3rd parties to read your COVID pass and reconstruct your NZCP QR code. This is bad since your pass could be then used by anyone. Never verify live passes as part of a transaction on a deployed version of this contract.

## Audits
N/A