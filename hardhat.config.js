require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: false,
        // runs: 1000,
      },
    },
  },

  // solidity: "",
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },

  gasReporter: {
    currency: 'USD',
    gasPrice: 80
  }
};
