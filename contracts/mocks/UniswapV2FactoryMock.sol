pragma solidity =0.6.12;

import "@sushiswap/core/contracts/uniswapv2/UniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";

contract UniswapV2FactoryMock is UniswapV2Factory {
    constructor(address _feeToSetter) public UniswapV2Factory(_feeToSetter) {}
}
