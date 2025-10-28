// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Referral is Ownable {
    // simple two-level referral mapping
    mapping(address => address) public referrer; // user -> referrer

    event Referred(address indexed user, address indexed referrer);

    function setReferrer(address user, address _referrer) external onlyOwner {
        referrer[user] = _referrer;
        emit Referred(user, _referrer);
    }

    function getReferrer(address user) external view returns (address) {
        return referrer[user];
    }
}
