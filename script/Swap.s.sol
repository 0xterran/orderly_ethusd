// $ forge script script/Swap.s.sol:SwapScript --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --verify

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {SwapV1} from "../src/SwapV1.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SwapScript is Script {

    function setUp() public {}

    function run() public {

        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(ownerPrivateKey);

        address owner = vm.envAddress("OWNER_ADDRESS");
        address pricefeed = vm.envAddress("CHAINLINK_FEED_ETHUSD");
        
        // Deploy MockUSDC
        MockUSDC usdcDeployed = new MockUSDC(1000 * 10**6); // 1000 MockUSDC with 6 decimals
        address usdc = address(usdcDeployed);
        console.log("MockUSDC deployed at:", usdc);

        // deploy the implementation without initializing
        SwapV1 swapv1 = new SwapV1();
        bytes memory initData = abi.encodeWithSelector(
            SwapV1.initialize.selector,
            owner, 
            pricefeed, 
            usdc
        );
        // Deploying the proxy with the encoded initializer call
        ERC1967Proxy proxy = new ERC1967Proxy(address(swapv1), initData);
        SwapV1 swapBehindProxy = SwapV1(address(proxy));

        console.log("Swap contract deployed behind proxy at:", address(swapBehindProxy));

        // // Deposit 0.01 ETH and 1 USDC into the Swap contract
        // usdcDeployed.approve(address(swapBehindProxy), 1 * 10**6); // Approve 1 USDC
        // swapBehindProxy.depositInventory{value: 0.01 ether}(1 * 10**6); // Deposit 1 USDC
        // console.log("Deposited 0.01 ETH and 1 USDC into the Swap contract");

        vm.stopBroadcast();
    }
}
