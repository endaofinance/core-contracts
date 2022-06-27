// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEndaoment is IERC20 {
    function mint(uint256 amountOfAssetsToLock) external;

    function burn(uint256 amountOfTokensToBurn) external;

    function epoch() external;

    function asset() external view returns (address);

    function epochDrawBips() external view returns (uint64);

    function epochDurationSecs() external view returns (uint64);

    function metadataURI() external view returns (string memory);

    function lastEpochTimestamp() external view returns (uint256);
}
