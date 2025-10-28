const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with", deployer.address);

  const TAK = await hre.ethers.getContractFactory("TAKULAI");
  // provide wallets for distribution (for demo purpose use deployer addresses)
  const tak = await TAK.deploy(deployer.address, deployer.address, deployer.address, deployer.address);
  await tak.deployed();
  console.log("TAKULAI deployed to", tak.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
