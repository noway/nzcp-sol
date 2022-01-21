# NZCP.sol

Commands:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

## Features
TODO

## Usage
TODO

## Test
```bash
make test
```

## Privacy implications
When you call `NZCP.readCredSubj` function as part of a transaction, your pass gets stored on blockchain as calldata. This allows 3rd parties to read your COVID pass and reconstruct your NZCP QR code. This is bad since your pass could be then used by anyone. Never verify live passes as part of a transaction on a deployed version of this contract.

## Audits
To be audited...