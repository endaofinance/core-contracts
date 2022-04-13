// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Endaoment.sol";
import "../libraries/EndaoLibrary.sol";
import "./IAsset.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EndaomentFactory is Ownable {
    using SafeERC20 for IERC20;
    address[] public endaomentAddresses;

    function createSushiEndaomant(
        string memory name_,
        string memory symbol_,
        uint256 epochDrawBips_,
        uint256 epochDuration_,
        address sushiFactory_,
        address token0_,
        address token1_
    ) public returns (address createdAddress) {
        address pair_ = EndaoLibrary.getUniswapV2PairAddress(sushiFactory_, token0_, token1_);
        IERC20 asset_ = IERC20(pair_);
        Endaoment endaoment = new Endaoment(name_, symbol_, epochDrawBips_, epochDuration_, asset_);
        createdAddress = address(endaoment);
        endaomentAddresses.push(createdAddress);
    }

    function getEndaoment(uint256 id) public view returns (address endaomentAddy) {
        return endaomentAddresses[id];
    }
}
