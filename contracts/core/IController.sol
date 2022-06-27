// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IController {
    function protocolFeeBips() external view returns (uint256);

    function treasuryAddress() external view returns (address);

    function distributitorFeeBips() external view returns (uint256);

    function setProtocolFee(uint256 bips) external;

    function setTreasury(address target) external;

    function setDistributorFee(uint256 bips) external;
}
