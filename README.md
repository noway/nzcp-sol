# NZCP.sol

Commands:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/deploy-script.js
npx hardhat help
```

## Features
TODO

## Usage
- Prepare `ToBeSigned` value and the `rs` array by calling `getToBeSignedAndRs` on your pass
- Call either `nzcp.readCredSubjExample(ToBeSigned, rs)` or `nzcp.readCredSubjLive(ToBeSigned, rs)` to verify your pass and get the credential subject

## Tests
- Create `.env` file in the root directory of the project
- Populate it with at least 1 live pass URI. 
    - Use `.env.example` as a reference.
- Run `make test`

## Privacy implications
When you call `NZCP.readCredSubj` function as part of a transaction, your pass gets stored on blockchain as calldata. This allows 3rd parties to read your COVID pass and reconstruct your NZCP QR code. This is bad since your pass could be then used by anyone. Never verify live passes as part of a transaction on a deployed version of this contract.

## Audits
To be audited...