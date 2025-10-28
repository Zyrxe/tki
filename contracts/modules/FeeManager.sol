// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeManager is Ownable {
    IERC20 public token;
    address public burnReserve;

    event FeesCollected(address from, uint256 amount);
    event BurnReserveTopped(address to, uint256 amount);

    constructor(IERC20 _token, address _burnReserve) {
        token = _token;
        burnReserve = _burnReserve;
    }

    function collectFees(address from, uint256 amount) external onlyOwner {
        // owner (TKI token contract) will call this to record fees; in real setup token would transfer fees here
        emit FeesCollected(from, amount);
    }

    function topUpBurnReserve(uint256 amount) external onlyOwner {
        token.transferFrom(msg.sender, burnReserve, amount);
        emit BurnReserveTopped(burnReserve, amount);
    }
}
