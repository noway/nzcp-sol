const hre = require("hardhat");

async function main() {
  const NZCP = await hre.ethers.getContractFactory("NZCP");
  const nzcp = await NZCP.deploy("Hello, Hardhat!");

  await nzcp.deployed();

  console.log("NZCP deployed to:", nzcp.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
