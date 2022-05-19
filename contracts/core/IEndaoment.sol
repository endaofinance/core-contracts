// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEndaoment is IERC20 {
    function mint(uint256 amountOfAssetsToLock) external;

    function burn(uint256 amountOfTokensToBurn) external;

    function claim() external returns (uint256 callerAmount);

    function epoch() external;

    function asset() external;

    function epochDrawBips() external;

    function epochDurationSecs() external;

    function metadataURI() external;
}
