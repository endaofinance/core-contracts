// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Treasury is Ownable {
    using SafeERC20 for IERC20;

    function claimERC20(
        address assetAddress,
        uint256 amount,
        address target
    ) external onlyOwner returns (uint256 claimed) {
        IERC20 asset = IERC20(assetAddress);
        asset.transfer(target, amount);
    }
}
