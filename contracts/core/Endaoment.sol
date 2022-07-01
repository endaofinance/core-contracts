// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IController.sol";

import "hardhat/console.sol";

contract Endaoment is AccessControlEnumerable, ERC20Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event EpochAttempt(address sender, uint256 timestamp);
    event EpochSuccess(address sender, uint256 timestamp);
    event Distribute(address target, uint256 beneficiaryAmount, uint256 protocolFee, uint256 distributitorFee);
    address immutable controllerAddress;

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
        address controller_,
        uint64 epochDrawBips_,
        uint64 epochDuration_,
        address asset_,
        string memory metadataURI_
    ) ERC20(name_, symbol_) {
        require(beneficiary_ != address(0), "BENEFICIARY_CAN_NOT_BE_0_ADDRESS");
        // Roles
        _setRoleAdmin(BENEFICIARY_ROLE, BENEFICIARY_ROLE); // Benificiary can admin its self
        _grantRole(BENEFICIARY_ROLE, beneficiary_);

        // Other Configuration
        controllerAddress = controller_;
        lastEpochTimestamp = uint64(block.timestamp);
        epochDrawBips = epochDrawBips_;
        epochDurationSecs = epochDuration_;
        asset = asset_;
        metadataURI = metadataURI_;
    }

    receive() external payable {
        require(false, "ETH_NOT_ACCEPTED");
    }

    function addBenificiary(address newBenificiary) public {
        _grantRole(BENEFICIARY_ROLE, newBenificiary);
    }

    function removeBenificiary(address target) public {
        _revokeRole(BENEFICIARY_ROLE, target);
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
        burnTo(tokensToBurn_, _msgSender());
    }

    function burnTo(uint256 tokensToBurn_, address target) public {
        IERC20 assetContract = IERC20(asset);
        uint256 assetSupply = assetContract.balanceOf(address(this));

        require(balanceOf(target) >= tokensToBurn_, "NOT_ENOUGH_TOKENS_TO_BURN");

        uint256 outboundAssets = tokensToBurn_.mul(assetSupply).div(totalSupply());

        _burn(target, tokensToBurn_);
        assetContract.safeTransfer(target, outboundAssets);
    }

    function calculateClaimable(address distributor)
        public
        view
        returns (
            uint256 claimable,
            uint256 protocolFee,
            uint256 distributitorFee
        )
    {
        claimable = balanceOf(address(this));
        IController controller = IController(controllerAddress);

        protocolFee = claimable.mul(controller.protocolFeeBips()).div(10000);
        distributitorFee = claimable.mul(controller.distributitorFeeBips()).div(10000);
        claimable = claimable.sub(protocolFee).sub(distributitorFee);

        // If the caller is a beneficiary give them the distributitorFee as well
        if (hasRole(BENEFICIARY_ROLE, distributor)) {
            claimable = claimable.add(distributitorFee);
            distributitorFee = 0;
        }

        return (claimable, protocolFee, distributitorFee);
    }

    function distribute(address target)
        public
        returns (
            uint256 beneficiaryAmount,
            uint256 protocolFee,
            uint256 distributitorFee
        )
    {
        require(hasRole(BENEFICIARY_ROLE, target), "TARGET_DOES_NOT_HAVE_BENIFICIARY_ROLE");

        IController controller = IController(controllerAddress);

        (beneficiaryAmount, protocolFee, distributitorFee) = calculateClaimable(_msgSender());

        if (protocolFee > 0) {
            _transfer(address(this), controller.treasuryAddress(), protocolFee);
        }

        if (distributitorFee > 0) {
            require(
                hasRole(BENEFICIARY_ROLE, _msgSender()) || balanceOf(_msgSender()) > 0,
                "DISTRIBUTOR_NOT_VAULT_MEMBER"
            );
            _transfer(address(this), _msgSender(), distributitorFee);
        }

        _transfer(address(this), target, beneficiaryAmount);

        emit Distribute(target, beneficiaryAmount, protocolFee, distributitorFee);
    }

    function distributeAndBurn(address target) public {
        (uint256 beneficiaryAmount, , ) = distribute(target);
        burnTo(beneficiaryAmount, target);
    }

    function epoch() public {
        uint64 t0 = uint64(block.timestamp);
        emit EpochAttempt(_msgSender(), t0);

        uint64 timeSinceLastEpoch = uint64(t0) - lastEpochTimestamp;
        require(timeSinceLastEpoch >= epochDurationSecs, "NOT_ENOUGH_TIME_HAS_PASSED_FOR_NEW_EPOCH");

        uint256 inflationAmount = totalSupply().sub(balanceOf(address(this))).mul(epochDrawBips).div(10000);

        require(inflationAmount > 0, "INFLATION_AMOUNT_ZERO");

        _mint(address(this), inflationAmount); // Inflate supply

        // Reset epoch
        lastEpochTimestamp = t0;
        emit EpochSuccess(_msgSender(), t0);
    }

    function epochAndDistribute(address target) public {
        epoch();
        distributeAndBurn(target);
    }

    function decimals() public view virtual override returns (uint8) {
        IERC20Metadata assetContract = IERC20Metadata(asset);
        return assetContract.decimals();
    }
}
