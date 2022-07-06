// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IController {
    function protocolFeeBips() external view returns (uint64);

    function treasuryAddress() external view returns (address);

    function distributitorFeeBips() external view returns (uint64);

    function setProtocolFee(uint64 bips) external;

    function setTreasury(address target) external;

    function setDistributorFee(uint64 bips) external;
}
