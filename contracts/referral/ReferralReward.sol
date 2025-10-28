// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ReferralReward is Ownable {
    using SafeMath for uint256;
    IERC20 public token;
    address public rewardPool; // marketing/reward pool address

    // levels: level1 gets 3%, level2 gets 1% (of purchased tokens) by default
    uint256 public level1Percent = 3;
    uint256 public level2Percent = 1;

    event RewardPaid(address indexed ref, uint256 amount, uint256 level);

    constructor(IERC20 _token, address _rewardPool) {
        token = _token;
        rewardPool = _rewardPool;
    }

    function setRewardPool(address _pool) external onlyOwner {
        rewardPool = _pool;
    }

    function setPercents(uint256 l1, uint256 l2) external onlyOwner {
        level1Percent = l1;
        level2Percent = l2;
    }

    // pay referral rewards; caller (e.g., presale) provides beneficiary and their referrers
    function payReferralRewards(address buyer, address ref1, address ref2, uint256 purchasedAmount) external onlyOwner {
        if (ref1 != address(0) && level1Percent > 0) {
            uint256 amt = purchasedAmount.mul(level1Percent).div(100);
            // transfer from rewardPool to ref1
            token.transferFrom(rewardPool, ref1, amt);
            emit RewardPaid(ref1, amt, 1);
        }
        if (ref2 != address(0) && level2Percent > 0) {
            uint256 amt2 = purchasedAmount.mul(level2Percent).div(100);
            token.transferFrom(rewardPool, ref2, amt2);
            emit RewardPaid(ref2, amt2, 2);
        }
    }
}
