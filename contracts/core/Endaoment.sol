// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Dev deps
import "hardhat/console.sol";

struct UniswapV2Asset {
    address erc20Contract;
    address routerContract;
}

contract Endaoment is AccessControlEnumerable, ERC20Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event HardBurn(uint256 amount);
    UniswapV2Asset public _asset;
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");
    bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
    address _manager;
    uint256 _targetReserveBips;
    uint256 _epochDrawBips;
    uint256 _epochsPerAnum = 12;

    // 18 decimals by default
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 annualDrawBips_,
        uint256 targetReserveBips_,
        address manager_,
        address assetErc20_,
        address assetRouter_
    ) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BENEFICIARY_ROLE, _msgSender());
        _grantRole(REBALANCER_ROLE, _msgSender());
        _epochDrawBips = annualDrawBips_.div(_epochsPerAnum);
        _targetReserveBips = targetReserveBips_;
        _manager = manager_;
        _asset = UniswapV2Asset({erc20Contract: assetErc20_, routerContract: assetRouter_});
    }

    receive() external payable {
        uint256 price_;
        uint256 supply_ = totalSupply();

        if (supply_ == 0) {
            // Initial price
            price_ = 1; // 1 wei
        } else {
            uint256 value_ = totalValue().sub(msg.value); // Pre money value
            price_ = value_.div(supply_);
        }

        uint256 amount = msg.value / price_;

        super._mint(_msgSender(), amount);
    }

    function mint(address asset_, uint256 amount_) external {
        uint256 price_;
        uint256 supply_ = totalSupply();

        IERC20 assetContract = IERC20(_asset.erc20Contract);
        assetContract.safeTransferFrom(_msgSender(), address(this), amount_);

        uint256 value = 1; // TODO: calculate value of deposit in ETH

        // Get value of assets
        if (supply_ == 0) {
            // Initial price
            price_ = 1; // 1 wei
        } else {
            uint256 value_ = totalValue().sub(value);
            price_ = value_.div(supply_);
        }

        uint256 contractAmount = value.div(price_);
        super._mint(_msgSender(), contractAmount);
    }

    function price() public view returns (uint256) {
        uint256 supply_ = totalSupply();
        if (supply_ == 0) {
            // Initial price
            return 1; // 1 wei
        }

        uint256 value_ = totalValue();
        return value_ / supply_;
    }

    function burn(uint256 amount) public virtual override {
        uint256 outboundTarget = amount.mul(price());
        require(address(this).balance >= outboundTarget, "Reserve does not have enough balance, try calling hardBurn");

        (bool sent, ) = _msgSender().call{value: outboundTarget}("");
        require(sent, "Failed to send Ether to burner");

        // Burn wont allow me to burn tokens I dont have
        super._burn(_msgSender(), amount); // TODO: can msg.sender be a 0 address?
    }

    // Return the value of the contract in wei
    function totalValue() public view returns (uint256) {
        uint256 lpValue = 0;

        //IERC20 assetContract = IERC20(_asset.erc20Contract);
        //uint256 myBalance = assetContract.balanceOf(address(this));
        // price per asset
        //IUniswapV2Router02 router = IUniswapV2Router02(_asset.routerContract);

        return lpValue.add(address(this).balance);
    }

    function rebalance() public {
        // Calculate midprice of pair
        // + / - a target % gain
        // Sell everything
        // withold reserve
        // safe approve

        // Inflate supply so that the benificiary can claim new supply
        uint256 benificiaryInflationAmount = (totalSupply() * _epochDrawBips).div(10000);
        super._mint(address(this), benificiaryInflationAmount); // Inflate supply to assigm value to the claimers

        uint256 reserveAmount = address(this).balance.mul(_targetReserveBips).div(10000);
        uint256 totalAmount = address(this).balance.sub(reserveAmount);

        require(totalAmount > 1, "Total amount to rebalance needs too be greater then 1");

        (bool sent, ) = _manager.call{value: totalAmount}("");
        require(sent, "Failed to send Ether to manager");
    }
}
