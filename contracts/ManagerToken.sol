// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

// Dev deps
import "hardhat/console.sol";

contract ManagerToken is AccessControlEnumerable, ERC20 {
    event HardBurn(uint256 amount);
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");
    bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
    address _manager;
    uint256 _targetReserveBips;
    uint256 _epochDrawBips;
    uint256 _epochsPerAnum = 12;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 annualDrawBips_,
        uint256 targetReserveBips_,
        address manager_
    ) ERC20(name_, symbol_) {
        // 18 decimals by default
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BENEFICIARY_ROLE, _msgSender());
        _setupRole(REBALANCER_ROLE, _msgSender());
        _epochDrawBips = annualDrawBips_ / _epochsPerAnum;
        _targetReserveBips = targetReserveBips_;
        _manager = manager_;
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
            price_ = value_ / supply_;
        }

        uint256 amount = msg.value / price_;

        super._mint(_msgSender(), amount);
    }

    function price() public view virtual returns (uint256) {
        uint256 supply_ = totalSupply();
        if (supply_ == 0) {
            // Initial price
            return 1; // 1 wei
        }

        uint256 value_ = totalValue();
        return value_ / supply_;
    }

    //function burn(uint256 amount) public virtual {
    //uint256 callerEquity = myEquity();

    //uint256 reserveBalance = address(this).balance;
    //require(reserveBalance >= callerEquity, "Reserve does not have enough balance, try calling hardBurn");

    //transfer(_msgSender(), callerEquity);
    //super._burn(_msgSender(), amount); // TODO: can msg.sender be a 0 address?
    //}

    // Execute rebalance witholding equity amount and then burns the token
    //function hardBurn(uint256 tokenAmount) public virtual {
    //uint256 targetEquity = _calculateEquity(tokenAmount);
    //require(targetEquity >= totalValue(), "Not enough equity for a hardBurn");
    //rebalance(targetEquity);
    //burn(tokenAmount);
    //emit HardBurn(tokenAmount);
    //}

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

    function rebalance() public virtual {
        // Calculate midprice of pair
        // + / - a target % gain
        // Sell everything
        // withold reserve
        // safe approve

        // Inflate supply so that the benificiary can claim new supply
        uint256 inflationAmount = (totalSupply() * _epochDrawBips) / 10000;
        super._mint(address(this), inflationAmount); // Inflate supply to assigm value to the claimers

        uint256 reserveAmount = (address(this).balance * _targetReserveBips) / 10000;
        uint256 totalAmount = address(this).balance - reserveAmount;

        if (totalAmount <= 1) {
            return;
        }

        (bool sent, ) = _manager.call{value: totalAmount}("");
        require(sent, "Failed to send Ether");
    }

    //function claimFee(uint256 percentage) public virtual {
    //require(hasRole(CLAIMER_ROLE, _msgSender()), "Public key can not claimFee");
    //uint256 myBalance = balanceOf(address(this));
    //transfer(address(this), (myBalance * percentage) / 100);
    //}
}
