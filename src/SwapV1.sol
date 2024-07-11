// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";


contract SwapV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    address public usdc;
    AggregatorV3Interface public priceFeed;

    // events
    event Deposit(address indexed sender, uint256 usdcAmount, uint256 etherAmount);
    event Swap(address indexed sender, uint256 usdcIn, uint256 etherOut, uint256 etherIn, uint256 usdcOut);
    event Withdraw(address indexed destination, uint256 etherAmount, uint256 usdcAmount);

    /**
     * Network: Ethereum Sepholia Testnet
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    function initialize(
        address _owner,
        address _priceFeedAddress,
        address _usdc
    ) public initializer {
        __Ownable_init(); 
        __ReentrancyGuard_init();
        transferOwnership(_owner);  
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        usdc = _usdc;
    }

    function swapTokens(
        uint256 _usdcSellAmount
    ) public payable nonReentrant returns (uint256 _ethBuyAmount, uint256 _usdcBuyAmount) {
        uint256 _ethSellAmount = msg.value;
        // Get the latest price
        (,int256 price,,,) = priceFeed.latestRoundData();
        // calculate tokenOut based on tokenIn
        uint256 usdcBuyAmount = _ethSellAmount * uint256(price) / 1e18 / 1e2; 
        uint256 ethBuyAmount = _usdcSellAmount * 1e18 * 1e2 / uint256(price);
        // token contracts
        IERC20 usdcContract = IERC20(usdc);
        // handle USDC to ETH swap
        if (_usdcSellAmount > 0) {
            require(ethBuyAmount >  0, "ETH buy amount is zero");
            // usdc needs approval & transfer from sender to contract
            require(usdcContract.approve(address(this), _usdcSellAmount), "Approval failed");
            require(usdcContract.transferFrom(msg.sender, address(this), _usdcSellAmount), "Transfer failed");
        }
        // handle ETH to USDC swap
        if (_ethSellAmount > 0) {
            require(usdcBuyAmount > 0, "USDC buy amount is zero");
            // eth transfer from sender to contract already handled by msg.value
            // transfer tokenOut from contract to sender
            require(usdcContract.transfer(msg.sender, usdcBuyAmount), "Transfer failed");
        }
        // emit swap event
        emit Swap(msg.sender, _usdcSellAmount, uint256(ethBuyAmount), uint256(_ethSellAmount), uint256(usdcBuyAmount));

        // send the eth to the sender (placed near end to abide by checks-effects-interactions pattern to avoid reentrancy)
        payable(msg.sender).transfer(ethBuyAmount);
        
        // return tokenOut volume
        return (uint256(ethBuyAmount), uint256(usdcBuyAmount));
    }

    function depositInventory (
        int256 _usdcAmount
    ) onlyOwner public payable {
        // deposit inventory
        uint256 etherAmount = msg.value;
        // eth transfer from sender to contract already handled by msg.value
        // handle USDC deposit
        if (_usdcAmount > 0) {
            // approve tokenIn
            IERC20 usdcToken = IERC20(usdc);
            require(usdcToken.approve(address(this), uint256(_usdcAmount)), "Approval failed");
            // transfer tokenIn from sender to contract
            require(usdcToken.transferFrom(msg.sender, address(this), uint256(_usdcAmount)), "Transfer failed");
        }
        // emit deposit event
        emit Deposit(msg.sender, uint256(_usdcAmount), etherAmount);
    }

    function withdrawInventory () nonReentrant onlyOwner public returns (uint256, uint256) {
        // withdraw inventory
        uint256 usdcAmount = IERC20(usdc).balanceOf(address(this));
        uint256 etherAmount = address(this).balance;
        // transfer our USDC to owner
        if (usdcAmount > 0) {
            require(IERC20(usdc).transfer(owner(), usdcAmount), "Transfer failed");
        }
        // emit withdraw event
        emit Withdraw(owner(), etherAmount, usdcAmount);
        // transfer our ETH to owner
        if (etherAmount > 0) {
            payable(owner()).transfer(etherAmount);
        }
        // return inventory withdrawn
        return (etherAmount, usdcAmount);
    }


    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}
