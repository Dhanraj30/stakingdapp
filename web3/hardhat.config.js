
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
const PRIVATE_KEY = "c7cb73b8721dca345910b6c65f09db72aac755114afa54f02bca03fedfc0ac66";
const RPC_URL = "https://rpc.ankr.com/polygon_mumbai";
module.exports = {
  defaultNetwork: "polygon_mumbai",
  networks: {
    hardhat: {
      chainId: 80001,
    },
    polygon_mumbai: {
      url: "https://rpc.ankr.com/polygon_mumbai",
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};