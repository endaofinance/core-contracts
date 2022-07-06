// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
    address public treasuryAddress;
    uint64 public protocolFeeBips = 0;
    uint64 public distributitorFeeBips = 0;

    constructor(address _treasuryAddress) {
        treasuryAddress = _treasuryAddress;
    }

    function setTreasury(address target) public onlyOwner {
        treasuryAddress = target;
    }

    function setDistributorFee(uint64 bips) public onlyOwner {
        // 10000 bips max fee
        if (bips > 10000) {
            bips = 10000;
        }
        distributitorFeeBips = bips;
    }

    function setProtocolFee(uint64 bips) public onlyOwner {
        // 10000 bips max fee
        if (bips > 10000) {
            bips = 10000;
        }
        protocolFeeBips = bips;
    }
}
