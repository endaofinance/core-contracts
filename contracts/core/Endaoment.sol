// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// Dev deps
import "hardhat/console.sol";

contract Endaoment is AccessControlEnumerable, ERC20Burnable {
    using SafeERC20 for IERC20;
    event HardBurn(uint256 amount);
    mapping(address => bool) public _assets;
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
        address manager_,
        address _coreAsset
    ) ERC20(name_, symbol_) {
        // 18 decimals by default
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BENEFICIARY_ROLE, _msgSender());
        _grantRole(REBALANCER_ROLE, _msgSender());
        _epochDrawBips = annualDrawBips_ / _epochsPerAnum;
        _targetReserveBips = targetReserveBips_;
        _manager = manager_;
        _assets[_coreAsset] = true;
    }

    receive() external payable {
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

    function enableAsset(address asset_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admins can enable assets");
        _assets[asset_] = true;
    }

    function disableAsset(address asset_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admins can disableAsset assets");
        _assets[asset_] = false;
    }

    function mint(address asset_, uint256 amount_) external {
        uint256 price_;
        uint256 supply_ = totalSupply();

        require(_assets[asset_], "Asset must be enabled for deposit");
        IERC20 assetContract = IERC20(asset_);
        assetContract.safeTransferFrom(_msgSender(), address(this), amount_);

        uint256 value = 1; // TODO: calculate value of deposit in ETH

        // Get value of assets
        if (supply_ == 0) {
            // Initial price
            price_ = 1; // 1 wei
        } else {
            uint256 value_ = totalValue() - value;
            price_ = value_ / supply_;
        }

        uint256 contractAmount = value / price_;
        super._mint(_msgSender(), contractAmount);
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

    function burn(uint256 amount) public virtual override {
        uint256 outboundTarget = amount * price();
        require(address(this).balance >= outboundTarget, "Reserve does not have enough balance, try calling hardBurn");

        (bool sent, ) = _msgSender().call{value: outboundTarget}("");
        require(sent, "Failed to send Ether to burner");

        // Burn wont allow me to burn tokens I dont have
        super._burn(_msgSender(), amount); // TODO: can msg.sender be a 0 address?
    }

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

        require(totalAmount > 1, "Total amount to rebalance needs too be greater then 1");

        (bool sent, ) = _manager.call{value: totalAmount}("");
        require(sent, "Failed to send Ether to manager");
    }

    //function claimFee(uint256 percentage) public virtual {
    //require(hasRole(CLAIMER_ROLE, _msgSender()), "Public key can not claimFee");
    //uint256 myBalance = balanceOf(address(this));
    //transfer(address(this), (myBalance * percentage) / 100);
    //}
}
