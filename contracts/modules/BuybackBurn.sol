// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BuybackBurn is Ownable {
    IERC20 public token;
    address public burnReserve;

    event BoughtBack(uint256 ethSpent, uint256 tokensBurned);

    constructor(IERC20 _token, address _burnReserve) {
        token = _token;
        burnReserve = _burnReserve;
    }

    // Simplified buyback: owner moves tokens from burnReserve and burns them
    function burnFromReserve(uint256 amount) external onlyOwner {
        token.transferFrom(burnReserve, address(this), amount);
        // if token has burn function owner can't burn here; we assume token supports burn via transfer to zero
        token.transfer(address(0), amount);
        emit BoughtBack(0, amount);
    }
}
