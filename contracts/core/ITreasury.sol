// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ITreasury {
    function protocolFeeBips() external returns (uint256);

    function claimERC20(address assetAddress, uint256 amount) external returns (uint256 claimed);

    function setProtocolFee(uint256 bips) external;
}
