// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SwapV1.sol";

contract SwapV2 is SwapV1 {

    function getReserves () public view returns (uint256, uint256) {
        // return [ETH, USDC]
        return (address(this).balance, IERC20(usdc).balanceOf(address(this)));
    }


    // Helper function to get a price quote of a trade without execution
    // Not necessary but very convinent for market participants

    // function quoteSwap(
    //     uint256 _usdcSellAmount
    // ) public payable returns (uint256 _ethBuyAmount, uint256 _usdcBuyAmount) {
    //     uint256 _ethSellAmount = msg.value;
    //     // Get the latest price
    //     (,int256 price,,,) = priceFeed.latestRoundData();
    //     // calculate tokenOut based on tokenIn
    //     uint256 usdcBuyAmount = _ethSellAmount * uint256(price) / 1e8; 
    //     uint256 ethBuyAmount = _usdcSellAmount * 1e8 / uint256(price);
    //     // return tokenOut volume
    //     return (uint256(ethBuyAmount), uint256(usdcBuyAmount));
    // }
}
