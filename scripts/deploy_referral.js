const hre = require("hardhat");
async function main(){
  const [deployer] = await hre.ethers.getSigners();
  const tokenAddress = process.env.TOKEN_ADDRESS;
  const Referral = await hre.ethers.getContractFactory("Referral");
  const referral = await Referral.deploy();
  await referral.deployed();
  console.log("Referral:", referral.address);
  const ReferralReward = await hre.ethers.getContractFactory("ReferralReward");
  const rr = await ReferralReward.deploy(tokenAddress, deployer.address);
  await rr.deployed();
  console.log("ReferralReward:", rr.address);
}
main().catch((e)=>{console.error(e); process.exitCode = 1});
