import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const accounts =
  process.env.PK !== undefined
    ? [process.env.PK]
    : [
      // 以下账号会在gitlab上公开, 除了测试代币, 不要向它们转入任何有价值的代币.
      "4313d6bb58d91ad2d112ba1e9ec07852e0bd952809ecd83dfd6892b9f0799ad6", // 0xa994a8c305cba5932ec30f1331155035b09bf391
      "cc25edbbbbc186aeb8b58508d71efd757827ad62a07bd3354a283f17e0fb9d4a", // 0xa3f45b3ab5ff54d24d61c4ea3f39cc98ebcb3c7e
      "c7950f0124e0f11b08828cb8afcee1bc99e5d4b3815fec94d58a924a1e53b23d", // 0x11e07aed82f1210ddab32fcd9419f56162b2794f
      "f72d341dfd27c61968a205f3e691052a6e301dcd3a236b0cd2ef2057f247d8c4", // 0xe87bde923b1b0b48c2f9f946c386f30d1184458e
      "9ed5a2048801ee52450de66409916c04296dd18feb82daa94be901f22466c8c9", // 0x761eb5fc4fed1a96a2a2ab6f5be8516c50e3007b
    ];


const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      // viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    hecotest: {
      url: "https://http-testnet.hecochain.com",
      gas: 6000000,
      gasPrice: 5000000000, // 5gwei
      accounts,
    },
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/4458cf4d1689497b9a38b1d6bbf05e78",
      accounts,
    },
    polygon: {
      url: "https://rpc.ankr.com/polygon",
      accounts,
    },
    heco: {
      url: "https://http-mainnet.hecochain.com",
      accounts,
    },
    bsc: {
      url: "https://rpc.ankr.com/bsc",
      accounts,
      chainId: 56,
    },
    bsctest: {
      url: "https://data-seed-prebsc-2-s1.binance.org:8545",
      accounts,
      chainId: 97,
    },
  }
};

export default config;
