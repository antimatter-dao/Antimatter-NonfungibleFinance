require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-web3");
// const { projectId, mnemonic } = require('./secret.rinkeby.json');
const { projectId, mnemonic } = require('./secret.mainnet-matter.json');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${projectId}`,
      accounts: [mnemonic]
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${projectId}`,
      accounts: [mnemonic]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${projectId}`,
      accounts: [mnemonic]
    },
    bsc: {
      url: `https://bsc-dataseed.binance.org/`,
      accounts: [mnemonic]
    },
    fantom: {
      url: `https://rpc.ftm.tools/`,
      accounts: [mnemonic]
    },
    avax: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      accounts: [mnemonic]
    }
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  mocha: {
    timeout: 20000
  }
};
