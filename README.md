# Simple Swap Example

Create an upgradable Solidity smart contract to manage and exchange USDC tokens. The system
will allow users to deposit ETH and swap it for USDC with real-time ETH prices sourced from
Chainlink Functions.

## Video Walkthrough

- Watch the 👉 [video walkthrough](https://drive.google.com/file/d/1HJ4sfKeMXgSuiH54PiMwgjXM5V3glqoK/view?usp=sharing)
- See the code on 👉 [github](https://github.com/0xterran/orderly_ethusd)

## Deployed Contracts

Ethereum Sepolia Testnet with contracts verified:

- ✅ [USDC](https://sepolia.etherscan.io/address/0x707ed9E2C3D8A90653A460639Dc6D9B2CfF5e653#readContract) `0x707ed9E2C3D8A90653A460639Dc6D9B2CfF5e653`
- ✅ [Swap](https://sepolia.etherscan.io/address/0xdD936D90336eAd9F3d68Be5e806FbB8Cb26cBc27) `0xdD936D90336eAd9F3d68Be5e806FbB8Cb26cBc27`

## Deployment

First load your `.env` file with the right creds (I like to have a `.env.testnet` and `.env.local` to easily switch between the two, just copy paste their contents into `.env`)

_Deploy to Sepolia Testnet_
Make sure you are using values from `.env.testnet`
Make sure you have at least 0.2 ETH in your owner account to pay deployment fees.

```sh
$ forge clean
$ forge build
$ forge script script/Swap.s.sol:SwapScript --verify --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --chain-id 11155111 --broadcast
```

_Deploy to Local forked RPC_
Make sure you are using values from `.env.local`

```sh
$ anvil --fork-url <RPC_URL>
$ forge script script/Swap.s.sol:SwapScript
```

In case of issues, you can run foundry clean and try again:

```sh
$ foundry clean
```

## Tests

Test on local forked RPC

```sh
$ anvil --fork-url <RPC_URL>
$ forge test --match-path test/Swap.t.sol  --rpc-url http://127.0.0.1:8545
```
