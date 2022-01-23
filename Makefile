.PHONY: contracts/NZCP.sol

DFLAGS=-DEXPORT_EXAMPLE_FUNCS -DEXPORT_LIVE_FUNCS

all: contracts/NZCP.sol

contracts/NZCP.sol: templates/NZCP.sol
	rm -f $@
	cpp -P $(DFLAGS) $< > $@ 

node_modules/:
	yarn

test: contracts/NZCP.sol node_modules/
	npx hardhat test