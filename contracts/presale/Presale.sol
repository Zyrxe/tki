// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Presale is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    address public treasury; // where received funds go
    uint256 public priceUsdCents = 1259; // $12.59 => 1259 cents per TKI
    uint256 public softcapUsd = 5_000_000; // dollars
    uint256 public hardcapUsd = 20_000_000; // dollars
    uint256 public raisedUsd = 0;
    uint256 public startTime;
    uint256 public endTime;
    bool public finalized;

    // participant balances in tokens and vesting
    mapping(address => uint256) public purchasedTokens;
    mapping(address => bool) public vestingClaimed;

    // simple oracle: owner sets ETH price in USD cents
    uint256 public ethPriceUsdCents = 200_00; // default $2,000.00 => 200_000 cents

    event Purchased(address indexed buyer, uint256 usdValue, uint256 tokenAmount);

    constructor(IERC20 _token, address _treasury, uint256 _startTime, uint256 _endTime) {
        token = _token;
        treasury = _treasury;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setEthPriceUsdCents(uint256 _cents) external onlyOwner {
        ethPriceUsdCents = _cents;
    }

    receive() external payable {
        buyWithETH();
    }

    function buyWithETH() public payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "not live");
        require(!finalized, "finalized");
        require(msg.value > 0, "zero");

        // compute USD cents value of this ETH
        uint256 usdCents = msg.value.mul(ethPriceUsdCents).div(1e18);
        uint256 usd = usdCents.div(100);
        require(raisedUsd.add(usd) <= hardcapUsd, "hardcap reached");

        // compute token amount: tokens = (usdCents / priceUsdCents) * 1 TKI
        uint256 tokenAmount = usdCents.mul(1e18).div(priceUsdCents);
        purchasedTokens[msg.sender] = purchasedTokens[msg.sender].add(tokenAmount);

        raisedUsd = raisedUsd.add(usd);

        // forward ETH to treasury
        payable(treasury).transfer(msg.value);

        emit Purchased(msg.sender, usd, tokenAmount);
    }

    // finalize after sale ends; must have reached softcap to succeed
    function finalize() external onlyOwner {
        require(block.timestamp > endTime, "not ended");
        require(!finalized, "already");
        require(raisedUsd >= softcapUsd, "softcap not met");
        finalized = true;
    }

    // claim purchased tokens after 1 year from finalize
    function claimTokens() external {
        require(finalized, "not finalized");
        require(block.timestamp >= endTime + 365 days, "vesting: not unlocked");
        uint256 amount = purchasedTokens[msg.sender];
        require(amount > 0, "no tokens");
        purchasedTokens[msg.sender] = 0;
        // transfer tokens from presale contract balance to buyer
        require(token.transfer(msg.sender, amount), "transfer failed");
    }

    // refund if softcap not met after endTime
    function refund() external {
        require(block.timestamp > endTime, "not ended");
        require(raisedUsd < softcapUsd, "softcap met");
        uint256 amount = purchasedTokens[msg.sender];
        require(amount > 0, "no purchase");
        purchasedTokens[msg.sender] = 0;
        // refund logic: can't refund ETH because contract forwarded funds to treasury.
        // In production, implement refundable escrow. Here we revert to indicate not supported.
        revert("refund not implemented in demo");
    }
}
