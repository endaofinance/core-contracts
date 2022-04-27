// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// External interfaces
//import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
//import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";

// Dev deps
//import "hardhat/console.sol";

contract Endaoment is AccessControlEnumerable, ERC20Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event EpochAttempt(address sender, uint256 timestamp);
    event EpochSuccess(address sender, uint256 timestamp);

    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");
    bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
    uint256 immutable _epochDrawBips;
    uint256 immutable _epochDurationSecs;
    uint256 _lastEpochTimestamp;
    address public immutable _asset;

    // 18 decimals by default
    constructor(
        string memory name_,
        string memory symbol_,
        address beneficiary_,
        uint256 epochDrawBips_,
        uint256 epochDuration_,
        address asset_
    ) ERC20(name_, symbol_) {
        require(beneficiary_ != address(0), "BENEFICIARY_CAN_NOT_BE_0_ADDRESS");
        // Roles
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(REBALANCER_ROLE, _msgSender());
        _grantRole(BENEFICIARY_ROLE, beneficiary_);

        // Other Configuration
        _lastEpochTimestamp = block.timestamp;
        _epochDrawBips = epochDrawBips_;
        _epochDurationSecs = epochDuration_;
        _asset = asset_;
    }

    receive() external payable {
        require(false, "Contract does not accept ETH");
    }

    function mint(uint256 lockingAssets_) external {
        IERC20 assetContract = IERC20(_asset);

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

    function burn(uint256 tokensToBurn_) public virtual override {
        IERC20 assetContract = IERC20(_asset);
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

    function epoch() external {
        // TODO: validate message sender
        emit EpochAttempt(_msgSender(), block.timestamp);
        require(hasRole(REBALANCER_ROLE, _msgSender()), "DOES_NOT_HAVE_REBALANCER_ROLE");

        uint256 timeSinceLastEpoch = block.timestamp - _lastEpochTimestamp;
        require(timeSinceLastEpoch > _epochDurationSecs, "NOT_ENOUGH_TIME_HAS_PASSED_FOR_NEW_EPOCH");

        // Enough time has passed for an epoch
        _lastEpochTimestamp = block.timestamp;

        // TODO: round down
        uint256 benificiaryInflationAmount = totalSupply().mul(_epochDrawBips).div(1000);

        require(benificiaryInflationAmount > 0, "BENIFICIARY_INFLATION_ZERO");

        super._mint(address(this), benificiaryInflationAmount); // Inflate supply to assigm value to the claimers
        emit EpochSuccess(_msgSender(), block.timestamp);
    }
}
