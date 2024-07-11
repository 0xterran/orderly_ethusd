# Interview Programming Challenge: Development of an Upgradable ETH-USDC Exchange Contract

## Objective:

✅ Create an upgradable Solidity smart contract to manage and exchange USDC tokens. The system
will allow users to deposit ETH and swap it for USDC with real-time ETH prices sourced from
Chainlink Functions.

## Technical Requirements:

Solidity Contract (Smart Contract Development)

- Contract Implementation:
- ✅ Use the OpenZeppelin library to implement an upgradable smart contract.
- ✅ The contract should maintain a balance of USDC and provide functionality for
  users to deposit ETH.
- ✅ Develop a function to enable ETH for USDC swapping, with the exchange rate
  sourced from a Chainlink Functions.
- ✅ Implement owner-only withdrawal functions for ETH and USDC for simplicity.

- Oracle Integration:
- ✅ Integrate Chainlink Price Feeds to obtain live ETH-USDC exchange prices.
  Alternatively, explore using Paraswap.io APIs as a price feed source.

- Upgradeability Features:
- ✅ Ensure that the contract supports seamless upgrades without loss of the stored
  USDC or ETH balances. Utilize OpenZeppelin’s proxies for implementing
  upgradeable contracts.

## Testing and Deployment

- Unit Testing:
- ✅ Craft detailed unit tests using Hardhat or Foundry to validate all aspects of the
  contract, including its upgradeability, deposit functions, swap logic, and
  withdrawal mechanisms.

- ✅ Ensure that tests verify the integration with Chainlink and the correct computation
  of exchange rates.

- Contract Deployment:
- ✅ Deploy the contract to a public Ethereum testnet, such as Rinkeby, ensuring all
  functionalities are accessible and perform as expected.

- Source Code Verification:
- ✅ Conduct source code verification on Etherscan to ensure transparency and
  trustworthiness of the deployed contract.

## Documentation

- ✅ Provide comprehensive documentation that outlines the contract’s architecture, discusses
  any limitations, and offers detailed setup, testing, and operational instructions.

## Evaluation Criteria:

- ✅ Correctness: The contract must accurately perform all specified functionalities.
- ✅ Security: Implementations should address common security vulnerabilities within smart
  contract development.
- ✅ Code Quality: Code should be well-organized, thoroughly commented, and
  maintainable.
- ✅ Testing and Deployment: Emphasis will be placed on thorough testing and robust
  deployment practices.
