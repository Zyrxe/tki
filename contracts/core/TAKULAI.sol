// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * TAKULAI (TKI) ERC20 token
 *
 * - Total supply: 1_000_000_000 TKI
 * - Initial distribution set in constructor
 * - Burn mechanism: burnRate% per transfer taken from burnReserve (contract-held reserve)
 * - Fees allocated to burnReserve via feePercent
 * - Max buy / sell per tx enforced against AMM pairs mapping
 * - Cooldown optional
 *
 * NOTE: This is a pragmatic, audit-minded implementation for testing & demonstration.
 */
contract TAKULAI is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18;

    // distribution wallets (set at deploy)
    address public developerWallet;
    address public presaleWallet;
    address public liquidityWallet;
    address public marketingWallet;
    address public burnReserveWallet; // tokens held here represent burn reserve

    // Burn and fee settings
    uint256 public burnRatePercent = 5; // default 5%
    uint256 public feePercent = 2; // percent of transfer routed to burn reserve as fee

    // max tx limits (in tokens)
    uint256 public maxBuy = 5_000 * 10**18;
    uint256 public maxSell = 1_000 * 10**18;

    // cooldown
    bool public enableCooldown = false;
    uint256 public cooldownSeconds = 60;
    mapping(address => uint256) public lastTx;

    // AMM pairs (owner configurable)
    mapping(address => bool) public automatedMarketMakerPairs;
    bool public tradingOpen = false;

    event BurnReserveTopUp(address indexed from, uint256 amount);
    event BurnRateUpdated(uint256 oldRate, uint256 newRate);
    event FeePercentUpdated(uint256 oldFee, uint256 newFee);
    event AMMPairUpdated(address pair, bool enabled);

    constructor(
        address _developer,
        address _presale,
        address _liquidity,
        address _marketing
    ) ERC20("TAKULAI", "TKI") {
        require(_developer != address(0), "zero dev");
        require(_presale != address(0), "zero presale");
        require(_liquidity != address(0), "zero liquidity");
        require(_marketing != address(0), "zero marketing");

        developerWallet = _developer;
        presaleWallet = _presale;
        liquidityWallet = _liquidity;
        marketingWallet = _marketing;
        burnReserveWallet = address(this); // contract will hold burn reserve

        // mint full supply to owner first then distribute
        _mint(msg.sender, INITIAL_SUPPLY);

        // distribute according to tokenomics
        _transfer(msg.sender, developerWallet, 400_000_000 * 10**18);
        _transfer(msg.sender, presaleWallet, 250_000_000 * 10**18);
        _transfer(msg.sender, liquidityWallet, 150_000_000 * 10**18);
        _transfer(msg.sender, marketingWallet, 20_000_000 * 10**18);
        _transfer(msg.sender, burnReserveWallet, 180_000_000 * 10**18);
    }

    // Owner-only controls
    function setBurnRate(uint256 _percent) external onlyOwner {
        require(_percent <= 20, "too high");
        emit BurnRateUpdated(burnRatePercent, _percent);
        burnRatePercent = _percent;
    }

    function setFeePercent(uint256 _percent) external onlyOwner {
        require(_percent <= 10, "fee too high");
        emit FeePercentUpdated(feePercent, _percent);
        feePercent = _percent;
    }

    function setMaxBuy(uint256 _maxBuy) external onlyOwner {
        maxBuy = _maxBuy;
    }

    function setMaxSell(uint256 _maxSell) external onlyOwner {
        maxSell = _maxSell;
    }

    function setCooldown(bool _enabled, uint256 _seconds) external onlyOwner {
        enableCooldown = _enabled;
        cooldownSeconds = _seconds;
    }

    function setAMMPair(address pair, bool enabled) external onlyOwner {
        automatedMarketMakerPairs[pair] = enabled;
        emit AMMPairUpdated(pair, enabled);
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

    // Top up burn reserve by sending tokens to contract (owner-only helper)
    function topUpBurnReserve(uint256 amount) external onlyOwner {
        _transfer(msg.sender, burnReserveWallet, amount);
        emit BurnReserveTopUp(msg.sender, amount);
    }

    // Override _transfer to implement fees, burn from burnReserve and limits/cooldown
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(sender != address(0) && recipient != address(0), "zero addr");

        if (!tradingOpen) {
            // allow owner and distribution wallets to move prior to trading
            require(sender == owner() || recipient == owner() || sender == developerWallet || sender == presaleWallet || sender == liquidityWallet || sender == marketingWallet || recipient == developerWallet || recipient == presaleWallet || recipient == liquidityWallet || recipient == marketingWallet, "trading closed");
        }

        // cooldown
        if (enableCooldown && sender != owner() && recipient != owner()) {
            require(block.timestamp.sub(lastTx[sender]) >= cooldownSeconds, "cooldown sender");
            require(block.timestamp.sub(lastTx[recipient]) >= cooldownSeconds, "cooldown recipient");
            lastTx[sender] = block.timestamp;
            lastTx[recipient] = block.timestamp;
        }

        // Max buy / sell enforcement when AMM pairs involved
        if (automatedMarketMakerPairs[sender]) {
            // buy
            require(amount <= maxBuy, "exceeds max buy");
        } else if (automatedMarketMakerPairs[recipient]) {
            // sell
            require(amount <= maxSell, "exceeds max sell");
        }

        uint256 feeAmount = amount.mul(feePercent).div(100);
        uint256 transferAmount = amount;
        if (feeAmount > 0) {
            // send fee to burnReserveWallet
            super._transfer(sender, burnReserveWallet, feeAmount);
            transferAmount = amount.sub(feeAmount);
        }

        // normal transfer
        super._transfer(sender, recipient, transferAmount);

        // perform burn from burnReserve (if available)
        uint256 burnAmount = amount.mul(burnRatePercent).div(100);
        uint256 reserveBalance = balanceOf(burnReserveWallet);
        if (burnAmount > 0 && reserveBalance >= burnAmount) {
            // burn from contract-held reserve
            _burn(burnReserveWallet, burnAmount);
        }
    }
}
