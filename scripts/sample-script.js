const hre = require("hardhat");

async function main() {
  const NZCP = await hre.ethers.getContractFactory("NZCP");
  const greeter = await NZCP.deploy("Hello, Hardhat!");

  await greeter.deployed();

  console.log("NZCP deployed to:", greeter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
