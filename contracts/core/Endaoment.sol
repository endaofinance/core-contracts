// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITreasury.sol";

contract Endaoment is AccessControlEnumerable, ERC20Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event EpochAttempt(address sender, uint256 timestamp);
    event EpochSuccess(address sender, uint256 timestamp);
    address _treasuryAddress;

    bytes32 constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");

    address public immutable asset;
    uint64 public immutable epochDrawBips;
    uint64 public immutable epochDurationSecs;
    string public metadataURI;
    uint64 public lastEpochTimestamp;

    // 18 decimals by default
    constructor(
        string memory name_,
        string memory symbol_,
        address beneficiary_,
        address treasury_,
        uint64 epochDrawBips_,
        uint64 epochDuration_,
        address asset_,
        string memory metadataURI_
    ) ERC20(name_, symbol_) {
        require(beneficiary_ != address(0), "BENEFICIARY_CAN_NOT_BE_0_ADDRESS");
        // Roles
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BENEFICIARY_ROLE, beneficiary_);

        // Other Configuration
        _treasuryAddress = treasury_;
        lastEpochTimestamp = uint64(block.timestamp);
        epochDrawBips = epochDrawBips_;
        epochDurationSecs = epochDuration_;
        asset = asset_;
        metadataURI = metadataURI_;
    }

    receive() external payable {
        require(false, "ETH_NOT_ACCEPTED");
    }

    function mint(uint256 lockingAssets_) external {
        IERC20 assetContract = IERC20(asset);

        uint256 senderAssetAllowance = assetContract.allowance(_msgSender(), address(this));
        uint256 senderAssetBalance = assetContract.balanceOf(_msgSender());
        require(
            senderAssetBalance >= lockingAssets_ && senderAssetAllowance >= lockingAssets_,
            "NOT_ENOUGH_ASSETS_TO_LOCK"
        );

        uint256 lockedAssets = assetContract.balanceOf(address(this));

        uint256 tokens;
        if (totalSupply() != 0) {
            tokens = lockingAssets_.mul(totalSupply()).div(lockedAssets);
        } else {
            tokens = lockingAssets_; // Start off 1 to 1
        }

        assetContract.safeTransferFrom(_msgSender(), address(this), lockingAssets_);

        _mint(_msgSender(), tokens);
    }

    function burn(uint256 tokensToBurn_) public virtual override {
        IERC20 assetContract = IERC20(asset);
        uint256 assetSupply = assetContract.balanceOf(address(this));

        require(balanceOf(_msgSender()) >= tokensToBurn_, "NOT_ENOUGH_TOKENS_TO_BURN");

        uint256 outboundAssets = tokensToBurn_.mul(assetSupply).div(totalSupply());

        _burn(_msgSender(), tokensToBurn_);
        assetContract.safeTransfer(_msgSender(), outboundAssets);
    }

    function claim() public returns (uint256 callerAmount) {
        require(hasRole(BENEFICIARY_ROLE, _msgSender()), "DOES_NOT_HAVE_BENIFICIARY_ROLE");
        uint256 claimable = balanceOf(address(this));

        ITreasury treasury = ITreasury(_treasuryAddress);

        uint256 protocolFee = claimable.mul(treasury.protocolFeeBips()).div(10000);
        if (protocolFee > 0) {
            callerAmount = claimable.sub(protocolFee);
            _transfer(address(this), _treasuryAddress, protocolFee);
            _transfer(address(this), _msgSender(), callerAmount);
        } else {
            callerAmount = claimable;
            _transfer(address(this), _msgSender(), callerAmount);
        }
    }

    function epoch() external {
        uint64 t0 = uint64(block.timestamp);
        emit EpochAttempt(_msgSender(), t0);

        uint64 timeSinceLastEpoch = uint64(t0) - lastEpochTimestamp;
        require(timeSinceLastEpoch >= epochDurationSecs, "NOT_ENOUGH_TIME_HAS_PASSED_FOR_NEW_EPOCH");

        uint256 inflationAmount = totalSupply().sub(balanceOf(address(this))).mul(epochDrawBips).div(10000);

        require(inflationAmount > 0, "INFLATION_AMOUNT_ZERO");

        _mint(address(this), inflationAmount); // Inflate supply and allow to claim

        // Enough time has passed for an epoch
        lastEpochTimestamp = t0;
        emit EpochSuccess(_msgSender(), t0);
    }
}
