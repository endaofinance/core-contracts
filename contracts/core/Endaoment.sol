// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../libraries/EndaoLibrary.sol";

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
    uint256 _initialPrice = 1;

    // 18 decimals by default
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 annualDrawBips_,
        uint256 targetReserveBips_,
        address factory_,
        address router_,
        address token0_,
        address token1_
    ) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BENEFICIARY_ROLE, _msgSender());
        _grantRole(REBALANCER_ROLE, _msgSender());
        _epochDrawBips = annualDrawBips_.div(_epochsPerAnum);
        _targetReserveBips = targetReserveBips_;
        _asset = UniswapV2Asset({router: router_, factory: factory_, base: token0_, quote: token1_});
    }

    receive() external payable {
        require(false, "Contract does not accept ETH");
    }

    function mint(uint256 lockingAssets_) external {
        address pair = getPairAddress(_asset.factory, _asset.base, _asset.quote);
        IERC20 assetContract = IERC20(pair);

        uint256 senderBalance = assetContract.balanceOf(_msgSender());
        uint256 lockedAssets = assetContract.balanceOf(address(this));

        uint256 tokens;
        if (totalSupply() != 0) {
            tokens = lockingAssets_.mul(totalSupply()).div(lockedAssets);
        } else {
            tokens = lockingAssets_; // Start off 1 to 1
        }

        require(senderBalance >= lockingAssets_, "Not enough assets to lock");
        assetContract.safeTransferFrom(_msgSender(), address(this), lockingAssets_);

        _mint(_msgSender(), tokens);
    }

    function getPairAddress(
        address factory,
        address addr1,
        address addr2
    ) private view returns (address pair) {
        return EndaoLibrary.getUniswapV2PairAddress(factory, addr1, addr2);
    }

    function burn(uint256 tokensToBurn_) public virtual override {
        address pair = getPairAddress(_asset.factory, _asset.base, _asset.quote);
        IERC20 assetContract = IERC20(pair);
        uint256 assetSupply = assetContract.balanceOf(address(this));

        uint256 outbounAssets = tokensToBurn_.mul(assetSupply).div(totalSupply());

        assetContract.approve(address(this), outbounAssets);
        assetContract.safeTransferFrom(address(this), _msgSender(), outbounAssets);
        assetContract.approve(address(this), 0); // Sucks to have another gas opteration but this is more secure.

        _burn(_msgSender(), tokensToBurn_); // TODO: can msg.sender be a 0 address?
    }

    function claim() public returns (uint256 claimed) {
        require(hasRole(BENEFICIARY_ROLE, _msgSender()), "DOES_NOT_HAVE_BENIFICIARY_ROLE");
        claimed = balanceOf(address(this));
        transferFrom(address(this), _msgSender(), claimed);
    }

    function claimAndBurn() public returns (uint256 claimed) {
        require(hasRole(BENEFICIARY_ROLE, _msgSender()), "DOES_NOT_HAVE_BENIFICIARY_ROLE");
        claimed = claim();
        burn(claimed);
    }

    function epoch() public {
        // TODO: validate message sender
        // TODO: probably should be inflating linarly
        require(hasRole(REBALANCER_ROLE, _msgSender()), "DOES_NOT_HAVE_REBALANCER_ROLE");
        uint256 benificiaryInflationAmount = totalSupply().mul(_epochDrawBips).div(1000);
        if (benificiaryInflationAmount == 0) {
            return;
        }
        super._mint(address(this), benificiaryInflationAmount); // Inflate supply to assigm value to the claimers
    }
}
