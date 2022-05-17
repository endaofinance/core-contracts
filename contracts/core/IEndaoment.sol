// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEndaoment is IERC20 {
    function mint(uint256 lockingAssets_) external;

    function burn(uint256 tokensToBurn_) external;

    function claim() external returns (uint256 claimed);

    function epoch() external;
}
