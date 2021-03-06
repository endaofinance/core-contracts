require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require("hardhat-gas-reporter");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const KOVAN_XPRV = "";
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.11",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
          outputSelection: {
            "*": {
              "*": ["storageLayout"],
            },
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
          outputSelection: {
            "*": {
              "*": ["storageLayout"],
            },
          },
        },
      },
    ],
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: [process.env.XPRV],
    },
    rinkeby: {
      url: process.env.RINKEBY_URL,
      accounts: [process.env.XPRV],
    },
    ropsten: {
      url: process.env.ROPSTEN_URL,
      accounts: [process.env.XPRV],
    },
    kovan: {
      url: process.env.KOVAN_URL,
      accounts: [process.env.XPRV],
    },
  },
  gasReporter: {
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_APIKEY,
  },
};
