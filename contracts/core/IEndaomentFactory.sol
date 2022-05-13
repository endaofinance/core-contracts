// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IEndaomentFactory {
    function createErc20Endaoment(
        string memory name_,
        string memory symbol_,
        uint256 epochDrawBips_,
        uint256 epochDuration_,
        address erc20Contract_,
        string memory metadataURI_
    ) external returns (address createdAddress);

    function endaoments(uint256) external returns (address);

    function getAllEndaoments() external view returns (address[] memory);

    function getEndaomentsCreatedBy(address creatorAddress) external view returns (address[] memory);
}
