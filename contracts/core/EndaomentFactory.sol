// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Endaoment.sol";

contract EndaomentFactory is Ownable {
    event CreateEndaoment(address sender, uint256 timestamp, address endaomentAddresses, string endaomentType);
    mapping(address => uint256[]) public ownerEndaoments;
    address[] public endaoments;

    function createSushiEndaomant(
        string memory name_,
        string memory symbol_,
        uint256 epochDrawBips_,
        uint256 epochDuration_,
        address uniswapPair_
    ) external returns (address createdAddress) {
        address sender = _msgSender();
        Endaoment endaoment = new Endaoment(name_, symbol_, sender, epochDrawBips_, epochDuration_, uniswapPair_);

        createdAddress = address(endaoment);
        storeEndaoment(createdAddress, sender);

        emit CreateEndaoment(sender, block.timestamp, createdAddress, "SushiSwap");
    }

    function storeEndaoment(address endaomentAddress, address owner) private {
        uint256 idx = endaoments.length;
        endaoments.push(endaomentAddress);
        ownerEndaoments[owner].push(idx);
    }

    function getEndaoment(uint256 id) public view returns (address endaomentAddy) {
        return endaoments[id];
    }

    function getEndaoments(address creatorAddress) public view returns (uint256[] memory) {
        return ownerEndaoments[creatorAddress];
    }
}
