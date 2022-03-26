// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Endaoment.sol";

contract EndaomentFactory is Ownable {
    address[] public endaomentAddresses;

    function createSushiEndaomant(
        string memory name_,
        string memory symbol_,
        uint256 annualDrawBips_,
        uint256 targetReserveBips_,
        address sushiFactory_,
        address sushiRouter_,
        address token0_,
        address token1_
    ) public returns (address createdAddress) {
        Endaoment endaoment = new Endaoment(
            name_,
            symbol_,
            annualDrawBips_,
            targetReserveBips_,
            sushiFactory_,
            sushiRouter_,
            token0_,
            token1_
        );
        createdAddress = address(endaoment);
        endaomentAddresses.push(createdAddress);
    }

    function getEndaoment(uint256 id) public view returns (address endaomentAddy) {
        return endaomentAddresses[id];
    }
}
