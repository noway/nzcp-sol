.PHONY: contracts/NZCP.sol clean

DFLAGS=-DEXPORT_EXAMPLE_FUNCS -DEXPORT_LIVE_FUNCS

all: contracts/NZCP.sol

contracts/NZCP.sol: templates/NZCP.sol
	rm -f $@
	cpp -P $(DFLAGS) $< > $@ 

node_modules/:
	yarn

test: contracts/NZCP.sol node_modules/
	npx hardhat test

deploy: contracts/NZCP.sol node_modules/
	npx hardhat run scripts/deploy-script.js --network $(NETWORK)

clean:
	rm -rf cache
	rm -rf artifacts
	rm -rf node_modules