// $ forge test --match-path test/Swap.t.sol  --rpc-url http://127.0.0.1:8545 

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwapV1} from "../src/SwapV1.sol";
import {SwapV2} from "../src/SwapV2.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract SwapTest is Test {
    
    SwapV1 public swapBehindProxy;
    MockUSDC public usdcDeployed;
    address public pricefeed;

    address public owner;
    address public mockUser;

    function setUp() public {
        owner = vm.envAddress("OWNER_ADDRESS");
        mockUser = vm.envAddress("MOCK_USER_ADDRESS");
        pricefeed = vm.envAddress("CHAINLINK_FEED_ETHUSD");

        // Ensure the owner has some initial ETH for gas fees
        vm.deal(owner, 1 ether);
        vm.deal(mockUser, 1 ether);

        // Impersonate the owner for contract deployment
        vm.startPrank(owner);

        usdcDeployed = new MockUSDC(1000 * 10**6); // 1000 MockUSDC with 6 decimals
        address usdc = address(usdcDeployed);     
        usdcDeployed.transfer(mockUser, 100 * 10**6);

        // Assert that the mockUser received the correct amount of USDC
        uint256 mockUserBalance = usdcDeployed.balanceOf(mockUser);
        assertEq(mockUserBalance, 100 * 10**6, "mockUser did not receive the correct amount of USDC");

        // Assert that the owner has the correct remaining balance of USDC
        uint256 ownerBalance = usdcDeployed.balanceOf(owner);
        assertEq(ownerBalance, 900 * 10**6, "owner does not have the correct remaining amount of USDC");

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
        swapBehindProxy = SwapV1(address(proxy));
        console.log("Swap contract deployed behind proxy at:", address(swapBehindProxy));
    }

    // ✅ Tests depositing
    // ✅ Tests withdrawal permissons
    // ✅ Tests withdrawal
    function testDepositAndWithdrawal () public {

        vm.deal(owner, 1 ether);

        uint256 initialOwnerUsdcBalance = usdcDeployed.balanceOf(owner);
        uint256 depositUsdcAmount = 500 * 10**6; // 500 USDC
        uint256 depositEthAmount = 0.5 ether;

        // Impersonate the owner for USDC approval and transfer
        vm.startPrank(owner);

        // Approve the Swap contract to spend owner's USDC
        usdcDeployed.approve(address(swapBehindProxy), depositUsdcAmount);

        // Deposit USDC and ETH into the Swap contract
        swapBehindProxy.depositInventory{value: depositEthAmount}(int256(depositUsdcAmount));

        // Stop impersonation
        vm.stopPrank();

        // Check contract's USDC and ETH balance after deposit
        uint256 contractUsdcBalance = usdcDeployed.balanceOf(address(swapBehindProxy));
        uint256 contractEthBalance = address(swapBehindProxy).balance;
        assertEq(contractUsdcBalance, depositUsdcAmount, "Contract USDC balance mismatch after deposit");
        assertEq(contractEthBalance, depositEthAmount, "Contract ETH balance mismatch after deposit");

        // Attempt to withdraw as a non-owner (should fail)
        vm.startPrank(mockUser);
        vm.expectRevert("Ownable: caller is not the owner");
        swapBehindProxy.withdrawInventory();
        vm.stopPrank();

        // Impersonate the owner for withdrawal
        vm.startPrank(owner);
        (uint256 withdrawnEth, uint256 withdrawnUsdc) = swapBehindProxy.withdrawInventory();
        vm.stopPrank();

        // Check owner's USDC and ETH balance after withdrawal
        uint256 finalOwnerUsdcBalance = usdcDeployed.balanceOf(owner);
        assertEq(finalOwnerUsdcBalance, initialOwnerUsdcBalance, "Owner USDC balance mismatch after withdrawal");
        assertEq(withdrawnUsdc, depositUsdcAmount, "Withdrawn USDC amount mismatch");
        assertEq(withdrawnEth, depositEthAmount, "Withdrawn ETH amount mismatch");
    }

    // ✅ Tests swap logic
    // ✅ Tests chainlink math
    // ✅ Tests cumulative balances
    function testSwap() public {

        vm.deal(owner, 1 ether);
        vm.deal(mockUser, 1 ether);

        uint256 depositUsdcAmount = 500 * 10**6; // 500 USDC
        uint256 depositEthAmount = 0.5 ether;

        // Impersonate the owner for USDC approval and transfer
        vm.startPrank(owner);
        usdcDeployed.approve(address(swapBehindProxy), depositUsdcAmount);

        // Deposit USDC and ETH into the Swap contract
        swapBehindProxy.depositInventory{value: depositEthAmount}(int256(depositUsdcAmount));

        // Stop impersonation
        vm.stopPrank();

        // Check initial balances
        uint256 contractUsdcBalance = usdcDeployed.balanceOf(address(swapBehindProxy));
        uint256 contractEthBalance = address(swapBehindProxy).balance;

        assertEq(contractUsdcBalance, depositUsdcAmount, "Contract USDC balance mismatch after deposit");
        assertEq(contractEthBalance, depositEthAmount, "Contract ETH balance mismatch after deposit");

        // Get the latest price from Chainlink
        (, int256 price, , , ) = swapBehindProxy.priceFeed().latestRoundData();
        uint256 ethPrice = uint256(price);

        // // First swap: user sells 30 USDC
        uint256 usdcIn1 = 30 * 10**6;
        uint256 ethIn1 = 0 ether;
        (uint256 ethBought1, uint256 usdcBought1) = executeSwap(mockUser, usdcIn1, ethIn1, ethPrice);

        // Second swap: user sells 0.05 ETH
        uint256 usdcIn2 = 0;
        uint256 ethIn2 = 0.05 ether;
        (uint256 ethBought2, uint256 usdcBought2) = executeSwap(mockUser, usdcIn2, ethIn2, ethPrice);

        // Third swap: user sells both 5 USDC and 0.01 ETH
        uint256 usdcIn3 = 5 * 10**6;
        uint256 ethIn3 = 0.01 ether;
        (uint256 ethBought3, uint256 usdcBought3) = executeSwap(mockUser, usdcIn3, ethIn3, ethPrice);

        // final check contract balances
        // assert that contract final amounts are as expected
        assertEq(
            usdcDeployed.balanceOf(address(swapBehindProxy)), 
            depositUsdcAmount + usdcIn1 + usdcIn2 + usdcIn3 - usdcBought1 - usdcBought2 - usdcBought3,
            "Contract USDC balance mismatch after swaps"
        );
        assertEq(
            address(swapBehindProxy).balance, 
            depositEthAmount + ethIn1 + ethIn2 + ethIn3 - ethBought1 - ethBought2 - ethBought3,
            "Contract ETH balance mismatch after swaps"
        );
    }

    // ✅ Tests contract upgrade
    // ✅ Tests new functions available
    // ✅ Tests contract state preservation
    function testUpgrade() public {
        // deposit 500 USDC and 0.5 ETH into SwapV1
        uint256 initialUsdcDeposit = 500 * 10**6; // 500 USDC
        uint256 initialEthDeposit = 0.5 ether;
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        usdcDeployed.approve(address(swapBehindProxy), initialUsdcDeposit);
        swapBehindProxy.depositInventory{value: initialEthDeposit}(int256(initialUsdcDeposit));
        vm.stopPrank();

        // upgrade the contract with SwapV2
        SwapV2 swapv2 = new SwapV2();
        vm.startPrank(owner);
        swapBehindProxy.upgradeTo(address(swapv2));
        vm.stopPrank();
        // call the SwapV2.getReserves function
        // Check if the upgrade was successful by calling getReserves on SwapV2
        SwapV2 upgradedSwap = SwapV2(address(swapBehindProxy));
        (uint256 ethReserve, uint256 usdcReserve) = upgradedSwap.getReserves();
        // compare reserves of USDC & ETH to see if it matches the initial deposit (so we know upgrade worked)
        assertEq(ethReserve, initialEthDeposit, "ETH reserve mismatch after upgrade");
        assertEq(usdcReserve, initialUsdcDeposit, "USDC reserve mismatch after upgrade");
    }

    function executeSwap(address user, uint256 usdcAmount, uint256 ethAmount, uint256 ethPrice) internal returns (
        uint256 _ethBought, uint256 _usdcBought
    ) {
        vm.startPrank(user);

        // Approve the proxy contract to spend user's USDC if usdcAmount > 0
        if (usdcAmount > 0) {
            usdcDeployed.approve(address(swapBehindProxy), usdcAmount);
        }

        (uint256 ethBought, uint256 usdcBought) = swapBehindProxy.swapTokens{value: ethAmount}(usdcAmount);

        if (usdcAmount > 0) {
            uint256 expectedEthBought = usdcAmount * 1e18 * 1e2 / ethPrice;
            assertEq(ethBought, expectedEthBought, "ETH bought amount mismatch");
        }

        if (ethAmount > 0) {
            uint256 expectedUsdcBought = ethAmount * ethPrice / 1e18 / 1e2;
            assertEq(usdcBought, expectedUsdcBought, "USDC bought amount mismatch");
        }

        vm.stopPrank();

        return (ethBought, usdcBought);
    }

}
