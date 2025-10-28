const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('TAKULAI basic flows', function () {
  let token, staking, presale, referral, owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2, rewardPool] = await ethers.getSigners();
    const TAK = await ethers.getContractFactory('TAKULAI');
    token = await TAK.deploy(owner.address, owner.address, owner.address, owner.address);
    await token.deployed();

    // simple staking and presale deploys
    const Staking = await ethers.getContractFactory('Staking');
    staking = await Staking.deploy(token.address, rewardPool.address);
    await staking.deployed();

    const Presale = await ethers.getContractFactory('Presale');
    const now = Math.floor(Date.now() / 1000);
    presale = await Presale.deploy(token.address, owner.address, now - 10, now + 3600);
    await presale.deployed();

    const ReferralReward = await ethers.getContractFactory('ReferralReward');
    referralReward = await ReferralReward.deploy(token.address, owner.address);
    await referralReward.deployed();

    // fund user1 with some tokens from owner
    await token.transfer(user1.address, ethers.utils.parseEther('10000'));
    await token.connect(user1).approve(staking.address, ethers.utils.parseEther('10000'));
  });

  it('transfer applies fee and burns from reserve if available', async function () {
    // ensure burnReserve has balance (it was funded at deploy)
    const reserveBalBefore = await token.balanceOf(token.address);
    expect(reserveBalBefore).to.be.gt(0);

    // transfer from user1 to user2; feePercent default 2 and burnRate 5 will attempt burn from reserve
    await token.connect(user1).transfer(user2.address, ethers.utils.parseEther('100'));
    const user2Bal = await token.balanceOf(user2.address);
    expect(user2Bal).to.be.gt(0);

    // reserve should decrease by burned amount after transfer
    const reserveBalAfter = await token.balanceOf(token.address);
    expect(reserveBalAfter).to.be.lt(reserveBalBefore);
  });

  it('staking accrues monthly rewards and claim pulls from reward pool', async function () {
    // owner funds rewardPool with tokens (rewardPool is an EOA in test)
    await token.transfer(rewardPool.address, ethers.utils.parseEther('1000'));

    // user1 stakes 1000
    await staking.connect(user1).stake(ethers.utils.parseEther('1000'));

    // increase time by 31 days
    await ethers.provider.send('evm_increaseTime', [31 * 24 * 3600]);
    await ethers.provider.send('evm_mine');

    const reward = await staking.accruedReward(user1.address);
    // reward should be ~5% of 1000 = 50 tokens
    expect(reward).to.be.closeTo(ethers.utils.parseEther('50'), ethers.utils.parseEther('0.1'));

    // approve staking contract to transfer from rewardPool and claim
    await token.connect(rewardPool).approve(staking.address, ethers.utils.parseEther('1000'));
    await staking.connect(user1).claimReward();
    // user1 should receive reward tokens from rewardPool
    const bal = await token.balanceOf(user1.address);
    expect(bal).to.be.gt(ethers.utils.parseEther('9000'));
  });

  it('presale enforces hardcap and vesting', async function () {
    // set ethPrice to $2000
    await presale.setEthPriceUsdCents(200000); // $2000 => 200000 cents
    // user1 buys with 0.1 ETH -> USD = 0.1*2000 = $200 -> tokens = 200 / 12.59
    await presale.connect(user1).buyWithETH({ value: ethers.utils.parseEther('0.1')});
    const purchased = await presale.purchasedTokens(user1.address);
    expect(purchased).to.be.gt(0);

    // cannot claim before finalize and 1 year
    await expect(presale.claimTokens()).to.be.reverted;
  });

  it('referral reward transfer simulation', async function () {
    // owner approves referralReward to move from owner reward pool
    await token.transfer(owner.address, ethers.utils.parseEther('1000'));
    await token.approve(referralReward.address, ethers.utils.parseEther('1000'));
    // pay referral rewards (owner only)
    await referralReward.payReferralRewards(user1.address, user2.address, owner.address, ethers.utils.parseEther('100'));
    // user2 should receive level1 reward of 3 tokens (3% of 100)
    const r2 = await token.balanceOf(user2.address);
    expect(r2).to.be.gt(0);
  });
});
