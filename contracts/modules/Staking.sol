// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    address public rewardPool; // marketing/reward pool address holding tokens to pay rewards
    uint256 public rewardPercentPerMonth = 5; // 5% per month

    struct StakeInfo {
        uint256 amount;
        uint256 since;
        uint256 claimed;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(IERC20 _token, address _rewardPool) {
        token = _token;
        rewardPool = _rewardPool;
    }

    function setRewardPool(address _pool) external onlyOwner {
        rewardPool = _pool;
    }

    // Stake tokens (transfer tokens to this contract)
    function stake(uint256 amount) external {
        require(amount > 0, "zero");
        token.transferFrom(msg.sender, address(this), amount);
        StakeInfo storage s = stakes[msg.sender];
        s.amount = s.amount.add(amount);
        if (s.since == 0) s.since = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    // compute accrued reward (floor months)
    function accruedReward(address user) public view returns (uint256) {
        StakeInfo storage s = stakes[user];
        if (s.amount == 0 || s.since == 0) return 0;
        uint256 elapsed = block.timestamp.sub(s.since);
        uint256 monthsElapsed = elapsed.div(30 days);
        if (monthsElapsed == 0) return 0;
        uint256 totalReward = s.amount.mul(rewardPercentPerMonth).mul(monthsElapsed).div(100);
        return totalReward.sub(s.claimed);
    }

    // Claim rewards (paid from rewardPool)
    function claimReward() external {
        uint256 reward = accruedReward(msg.sender);
        require(reward > 0, "no reward");
        // Transfer from rewardPool to user
        require(token.transferFrom(rewardPool, msg.sender, reward), "reward transfer failed");
        stakes[msg.sender].claimed = stakes[msg.sender].claimed.add(reward);
        emit RewardClaimed(msg.sender, reward);
    }

    // Unstake (no penalties; rewards are independent)
    function unstake(uint256 amount) external {
        StakeInfo storage s = stakes[msg.sender];
        require(amount > 0 && amount <= s.amount, "invalid amount");
        s.amount = s.amount.sub(amount);
        // if all unstaked reset timer
        if (s.amount == 0) {
            s.since = 0;
            s.claimed = 0;
        }
        require(token.transfer(msg.sender, amount), "transfer failed");
        emit Unstaked(msg.sender, amount);
    }
}
