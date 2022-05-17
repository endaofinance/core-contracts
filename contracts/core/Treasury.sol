// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Treasury is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    uint256 public protocolFeeBips = 0;
    bytes32 constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    constructor(address claimer) {
        _grantRole(CLAIMER_ROLE, claimer);
    }

    function setProtocolFee(uint256 bips) external {
        require(hasRole(CLAIMER_ROLE, _msgSender()), "DOES_NOT_HAVE_CLAIMER_ROLE");
        protocolFeeBips = bips;
    }

    function claimERC20(address assetAddress, uint256 amount) external returns (uint256 claimed) {
        require(hasRole(CLAIMER_ROLE, _msgSender()), "DOES_NOT_HAVE_CLAIMER_ROLE");
        IERC20 asset = IERC20(assetAddress);
        asset.transfer(_msgSender(), amount);
    }
}
