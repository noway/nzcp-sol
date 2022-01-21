.PHONY: contracts/NZCP.sol

contracts/NZCP.sol: templates/NZCP.sol
	rm -f $@ && cpp -P $< > $@