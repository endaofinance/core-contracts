// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ITreasury {
    function claimERC20(
        address assetAddress,
        uint256 amount,
        address target
    ) external returns (uint256 claimed);
}
