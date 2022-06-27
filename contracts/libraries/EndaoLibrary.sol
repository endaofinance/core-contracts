// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";

library EndaoLibrary {
    function getUniswapV2PairAddress(
        address factory,
        address addr1,
        address addr2
    ) internal view returns (address pair) {
        IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);

        pair = factoryContract.getPair(addr1, addr2);
        require(pair != address(0), "Pair does not exist");
    }
}
