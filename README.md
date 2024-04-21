# SpaceCoin and ICO Contracts

## Overview

This repository contains the implementation of the SpaceCoin (SPC) ERC20 token and the associated Initial Coin Offering (ICO) contract written in Solidity. SpaceCoin is an ERC20 token with added functionality for enabling taxes on transfers, controllable by owner, and the ICO contract facilitates the distribution of tokens during different phases of the ICO.

### Implemented Features

- **SpaceCoin Token (ERC20)**
  - Minting of initial token supplies for treasury and ICO contract
    <details>
    <summary> Initial supply </summary>
    ICO 150_000

    Treasury 350_000
    </details>
  - Ability to toggle tax status, controllable by owner

- **ICO Contract**
  - Phased ICO with SEED, GENERAL, and OPEN phases
  - Contribution function allowing users to contribute ETH
    <details>
     <summary>Rules</summary>
     Only users in allowList can contribute in SEED phase.

     There is a limit of 1500 contributed ETH for users in SEED phase, and 1000 ETH in GENERAL phase.
     
     There is a total contribution limit of 15000ETH in SEED phase, and total contribution limit of 30000ETH in GENERAL and OPEN phase.
    </details>
  - Redemption function allowing users to redeem SPC tokens during the OPEN phase
  - Owner-controlled phase advancement
  - Owner-controlled pausing and resuming contributions and redemptions

## Deployment and Verification

The contracts have been deployed and verified on the Ethereum Sepolia testnet.

- **Contracts:** [Deployed Contract](https://sepolia.etherscan.io/token/0xb3bbdd9a920e9e3c5dacdf5cc26cf5808fe1e996#code)

## Test Coverage

| File                | % Lines         | % Statements    | % Branches     | % Funcs         |
| ------------------- | --------------- | --------------- | -------------- | --------------- |
| script/Deploy.s.sol | 100.00% (5/5)   | 100.00% (7/7)   | 100.00% (0/0)  | 100.00% (1/1)   |
| src/ICO.sol         | 100.00% (33/33) | 100.00% (41/41) | 90.00% (18/20) | 100.00% (6/6)   |
| src/SpaceCoin.sol   | 100.00% (15/15) | 100.00% (13/13) | 100.00% (4/4)  | 100.00% (5/5)   |
| Total               | 100.00% (53/53) | 100.00% (61/61) | 91.67% (22/24) | 100.00% (12/12) |

## Future Work
- **Withdrawing contributions** Implement functionality to withdraw the contributed ETH.
- **Dynamic Treasury Address:** Implement functionality to allow changing the treasury address if required.
- **Improved Testing:** Develop comprehensive test suites to ensure the contracts behave as expected under various conditions.
- **Gas Optimization:** Optimize gas usage to reduce transaction costs for users.
- **Enhanced Security:** Conduct security audits to identify and mitigate potential vulnerabilities.
- **User Interface:** Develop a user interface for interacting with the ICO contract, making contributions, and redeeming tokens.
- **Integration with Wallets:** Integrate the contracts with popular wallets to enhance accessibility for users participating in the ICO.