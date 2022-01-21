.PHONY: contracts/NZCP.sol

contracts/NZCP.sol: templates/NZCP.sol
	rm -f $@ && cpp -P $< > $@

test: contracts/NZCP.sol
	npx hardhat test