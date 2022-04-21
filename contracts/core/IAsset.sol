pragma solidity ^0.8.11;

interface IAsset {
    function safeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}
