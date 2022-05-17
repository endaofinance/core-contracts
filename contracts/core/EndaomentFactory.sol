// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Endaoment.sol";
import "./Treasury.sol";

contract EndaomentFactory is Ownable {
    address treasuryAddress;

    constructor() {
        Treasury treasury = Treasury(_msgSender());
        treasuryAddress = address(treasury);
    }

    event CreateEndaoment(
        address sender,
        uint256 timestamp,
        address endaomentAddresses,
        string endaomentType,
        uint256 endaomentsCount
    );
    mapping(address => address[]) creatorEndaoments;
    address[] public endaoments;

    function createErc20Endaoment(
        string memory name_,
        string memory symbol_,
        uint64 epochDrawBips_,
        uint64 epochDuration_,
        address erc20Contract_,
        string memory metadataURI_
    ) external returns (address createdAddress) {
        Endaoment endaoment = new Endaoment(
            name_,
            symbol_,
            _msgSender(),
            treasuryAddress,
            epochDrawBips_,
            epochDuration_,
            erc20Contract_,
            metadataURI_
        );

        endaoments.push(address(endaoment));
        creatorEndaoments[_msgSender()].push(address(endaoment));

        emit CreateEndaoment(_msgSender(), block.timestamp, address(endaoment), "ERC20", endaoments.length);
    }

    function getAllEndaoments() external view returns (address[] memory) {
        return endaoments;
    }

    function getEndaomentsCreatedBy(address creatorAddress) external view returns (address[] memory) {
        return creatorEndaoments[creatorAddress];
    }
}
