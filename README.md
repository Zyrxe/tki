TAKULAI (TKI) - Hardhat demo project
-----------------------------------

Files included:
- contracts/* : Solidity contracts (core, modules, presale, referral)
- scripts/* : deployment scripts
- test/* : basic unit tests
- hardhat.config.js, package.json, config/*

Notes:
- Contracts import OpenZeppelin. Run `npm install` before compile.
- To run tests:
    npm install
    npx hardhat test

- Deployment: set environment variables in .env (SEPOLIA_RPC, DEPLOYER_PRIVATE_KEY, TOKEN_ADDRESS)
