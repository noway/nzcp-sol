.PHONY: contracts/NZCP.sol

contracts/NZCP.sol: templates/NZCP.sol
	rm -f $@
	cpp -P -DEXPORT_EXAMPLE_FUNCS -DEXPORT_LIVE_FUNCS $< > $@ 

node_modules/:
	yarn

test: contracts/NZCP.sol node_modules/
	npx hardhat test