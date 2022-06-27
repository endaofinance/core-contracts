// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Endaoment.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract EndaomentFactory is Context {
    address immutable controllerAddress;
    event CreateEndaoment(
        address sender,
        uint256 timestamp,
        address endaomentAddresses,
        string endaomentType,
        uint256 endaomentsCount
    );
    mapping(address => address[]) creatorEndaoments;
    address[] public endaoments;

    constructor(address controllerAddress_) {
        controllerAddress = controllerAddress_;
    }

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
            controllerAddress,
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
