require("@nomiclabs/hardhat-waffle");
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
    kovan: {
      url: process.env.KOVAN_URL,
      accounts: [process.env.KOVAN_XPRV],
    },
  },
};
