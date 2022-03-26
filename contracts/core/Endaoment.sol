// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// External interfaces
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Dev deps
import "hardhat/console.sol";

struct UniswapV2Asset {
    address router;
    address factory;
    address base;
    address quote;
}

contract Endaoment is AccessControlEnumerable, ERC20Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    UniswapV2Asset public _asset;
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");
    bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
    uint256 _targetReserveBips;
    uint256 _epochDrawBips;
    uint256 _epochsPerAnum = 12;
    uint256 _initialPrice = 1 * 1e8;

    // 18 decimals by default
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 annualDrawBips_,
        uint256 targetReserveBips_,
        address factory_,
        address router_,
        address base_,
        address quote_
    ) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BENEFICIARY_ROLE, _msgSender());
        _grantRole(REBALANCER_ROLE, _msgSender());
        _epochDrawBips = annualDrawBips_.div(_epochsPerAnum);
        _targetReserveBips = targetReserveBips_;
        _asset = UniswapV2Asset({router: router_, factory: factory_, base: base_, quote: quote_});
    }

    receive() external payable {
        require(false, "Contract does not accept ETH");
    }

    function mint(uint256 lockedAssets_) external {
        address pair = getPairAddress(_asset.factory, _asset.base, _asset.quote);
        IERC20 assetContract = IERC20(pair);
        uint256 senderBalance = assetContract.balanceOf(_msgSender());
        require(senderBalance >= lockedAssets_, "Not enough assets to lock");
        assetContract.safeTransferFrom(_msgSender(), address(this), lockedAssets_);

        uint256 price = price();
        uint256 tokens = lockedAssets_.div(price);

        console.log("price (mint)", price);
        console.log("assetsRequired (mint)", lockedAssets_);
        console.log("Sender asset balance", senderBalance);

        super._mint(_msgSender(), tokens);
    }

    // TODO: move to lib
    function getPairAddress(
        address factory,
        address addr1,
        address addr2
    ) public view returns (address pair) {
        IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);

        pair = factoryContract.getPair(addr1, addr2);
        require(pair != address(0), "Pair does not exist");
    }

    // TODO: move to lib
    // TODO: explore better ways of calculating midprice
    //function getAssetMidPrice(
    //address factory,
    //address addr1,
    //address addr2
    //) public view returns (uint256) {
    //IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);
    //address pairAddress = factoryContract.getPair(addr1, addr2);
    //IERC20 token1 = IERC20(addr1);
    //IERC20 token2 = IERC20(addr2);
    //uint256 balance1 = token1.balanceOf(pairAddress);
    //uint256 balance2 = token2.balanceOf(pairAddress);
    //return balance2.div(balance1);
    //}

    // TODO: move to lib
    // Give me the assets this endaoment controls
    //function getAssetBalances(
    //address factory,
    //address addr1,
    //address addr2
    //) public view returns (uint256 balance1, uint256 balance2) {
    //IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);
    //address pairAddress = factoryContract.getPair(addr1, addr2);

    //// reserves
    //IERC20 pairToken = IERC20(pairAddress);
    //IERC20 token1 = IERC20(addr1);
    //IERC20 token2 = IERC20(addr2);

    //uint256 _totalSupply = pairToken.totalSupply();
    //uint256 liquidity = pairToken.balanceOf(address(this));

    //balance1 = token1.balanceOf(pairAddress);
    //balance2 = token2.balanceOf(pairAddress);

    //console.log("liquidity", liquidity);
    //console.log("totalSupply", _totalSupply);
    //console.log("balance1", balance1);
    //console.log("balance2", balance2);

    //balance1 = liquidity.mul(balance1).div(_totalSupply);
    //balance2 = liquidity.mul(balance2).div(_totalSupply);
    //}

    function postMoneyPrice(uint256 assumedSupply_) public view returns (uint256) {
        uint256 value_ = IERC20(getPairAddress(_asset.factory, _asset.base, _asset.quote)).balanceOf(address(this));
        console.log("value", value_);
        if (value_ == 0) {
            return _initialPrice;
        }
        console.log("assumedSupply", assumedSupply_);
        return value_.div(assumedSupply_);
    }

    function price() public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply > 0) {
            return postMoneyPrice(totalSupply());
        }

        return _initialPrice;
    }

    function burn(uint256 tokensToBurn_) public virtual override {
        uint256 assumedSupply = totalSupply().sub(tokensToBurn_);
        uint256 price = postMoneyPrice(assumedSupply);
        uint256 outboundTarget = tokensToBurn_.div(price);
        address pair = getPairAddress(_asset.factory, _asset.base, _asset.quote);
        IERC20 assetContract = IERC20(pair);
        assetContract.approve(address(this), outboundTarget);
        assetContract.safeTransferFrom(address(this), _msgSender(), outboundTarget);
        assetContract.approve(address(this), 0); // Sucks to have another gas opteration but this is more secure.
        super._burn(_msgSender(), tokensToBurn_); // TODO: can msg.sender be a 0 address?
    }

    function epoch() public {
        // TODO: validate message sender
        // TODO: probably should be inflating linarly
        uint256 benificiaryInflationAmount = totalSupply().mul(_epochDrawBips).div(1000);
        console.log("benificiaryInflationAmount", benificiaryInflationAmount);
        console.log("_epochDrawBips", _epochDrawBips);
        if (benificiaryInflationAmount == 0) {
            return;
        }
        super._mint(address(this), benificiaryInflationAmount); // Inflate supply to assigm value to the claimers
    }
}
