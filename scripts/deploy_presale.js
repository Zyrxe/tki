const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const tokenAddress = process.env.TOKEN_ADDRESS;
  const treasury = deployer.address;
  const start = Math.floor(Date.now() / 1000) + 10;
  const end = start + 3600 * 24 * 7; // 7 days
  const Presale = await hre.ethers.getContractFactory("Presale");
  const presale = await Presale.deploy(tokenAddress, treasury, start, end);
  await presale.deployed();
  console.log("Presale:", presale.address);
}

main().catch((e)=>{console.error(e); process.exitCode = 1});
