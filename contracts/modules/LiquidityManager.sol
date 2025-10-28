// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityManager is Ownable {
    IERC20 public token;
    address public router; // Uniswap router

    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount);

    constructor(IERC20 _token, address _router) {
        token = _token;
        router = _router;
    }

    // placeholder: in production we'd call router.addLiquidityETH
    function addLiquidity(uint256 tokenAmount) external payable onlyOwner {
        // expects owner to approve token transfer to this contract and send ETH
        // then in real scenario interact with router
        emit LiquidityAdded(tokenAmount, msg.value);
    }
}
