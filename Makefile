.PHONY: contracts/nzcp.sol

contracts/nzcp.sol: templates/nzcp.sol
	rm -f $@ && cpp -P $< > $@