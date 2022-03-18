// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
//import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

// Dev deps
import "hardhat/console.sol";

contract ManagerToken is AccessControlEnumerable, ERC20 {
    IQuoter public constant _quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");
    uint256 _targetReserve;
    uint256 _mgmtFee;
    uint256 _feeBasis;
    address immutable _baseToken;
    address immutable _quoteToken;
    event HardBurn(uint256 amount);

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CLAIMER_ROLE, _msgSender());
        //_mgmtFee = mgmtFee_; // Fee in thousands
        _baseToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // weth
        _quoteToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // usdc
        //super._mint(_msgSender(), 50);
        // 18 decimals by default
    }

    receive() external payable {
        // determine how mucch equity there is
        // determine how much user is depositing
        // accept deposit for the max amount
        // return leftover eth
        uint256 price_;
        uint256 supply_ = totalSupply();

        if (supply_ == 0) {
            // Initial price
            price_ = 1; // 1 wei
        } else {
            uint256 value_ = totalValue() - msg.value; // Pre money value
            console.log("supply", supply_);
            console.log("value", value_);
            price_ = value_ / supply_;
        }

        console.log("price", price_);
        console.log("depositAmount", msg.value);
        uint256 amount = msg.value / price_;
        console.log("amount", amount);

        super._mint(_msgSender(), amount);
    }

    function price() public view virtual returns (uint256) {
        uint256 supply_ = totalSupply();
        console.log("total supply", supply_);

        if (supply_ == 0) {
            // Initial price
            return 1; // 1 wei
        }

        uint256 value_ = totalValue();
        return value_ / supply_;
    }

    function burn(uint256 amount) public virtual {
        uint256 callerEquity = myEquity();

        uint256 reserveBalance = address(this).balance;
        require(
            reserveBalance >= callerEquity,
            "Reserve does not have enough balance, try calling hardBurn"
        );

        transfer(_msgSender(), callerEquity);
        super._burn(_msgSender(), amount); // TODO: can msg.sender be a 0 address?
    }

    // Execute rebalance witholding equity amount and then burns the token
    function hardBurn(uint256 tokenAmount) public virtual {
        uint256 targetEquity = _calculateEquity(tokenAmount);
        require(targetEquity >= totalValue(), "Not enough equity for a hardBurn");
        rebalance(targetEquity);
        burn(tokenAmount);
        emit HardBurn(tokenAmount);
    }

    // Return the value of the contract in wei
    function totalValue() public view virtual returns (uint256) {
        uint256 lpValue = 0;

        return lpValue + address(this).balance;
        // TODO:
        //uint256 quoteBalance = 0; // TODO: get balance of quote
        //uint256 baseBalance = 100; // TODO: gjt balance of base
        //uint24 fee = 3000;
        //uint160 sqrtPriceLimitX96 = 0;
        //uint256 quoteValue = _quoter.quoteExactInputSingle(
        //_baseToken,
        //_quoteToken,
        //fee,
        //baseBalance,
        //sqrtPriceLimitX96
        //);
        //return baseBalance + quoteValue;
        //// Add oge all eth
    }

    function _calculateEquity(uint256 tokenAmount) private returns (uint256) {
        uint256 nonFeeAmount = (tokenAmount * _mgmtFee) / _feeBasis;
        uint256 _totalValue = totalValue();
        return (nonFeeAmount / totalSupply()) * _totalValue;
    }

    function myEquity() public virtual returns (uint256) {
        uint256 amount = balanceOf(_msgSender());
        return _calculateEquity(amount);
    }

    function rebalance(uint256 additionalEquity) public virtual {
        // Calculate midprice of pair
        // + / - a target % gain
        // Sell everything
        // withold reserve
        // safe approve
    }

    function claimFee(uint256 percentage) public virtual {
        require(hasRole(CLAIMER_ROLE, _msgSender()), "Public key can not claimFee");
        uint256 myBalance = balanceOf(address(this));
        transfer(address(this), (myBalance * percentage) / 100);
    }
}
