const hre = require("hardhat");
async function main(){
  const [deployer] = await hre.ethers.getSigners();
  const tokenAddress = process.env.TOKEN_ADDRESS;
  const rewardPool = deployer.address;
  const Staking = await hre.ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(tokenAddress, rewardPool);
  await staking.deployed();
  console.log("Staking:", staking.address);
}
main().catch((e)=>{console.error(e); process.exitCode = 1});
