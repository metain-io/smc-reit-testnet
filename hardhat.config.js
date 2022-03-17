require('@openzeppelin/hardhat-upgrades');

const fs = require('fs');

const argv = require('minimist')(process.argv.slice(2));
const env = require('./env.json')[argv.network];
const secret = JSON.parse(fs.readFileSync('.secret'));

/**
 * Contract deployment task
 */
task('deploy', 'Deploy REIT NFT Contract')
  .addOptionalParam('token', 'Token address (without 0x)')
  .setAction(async () => {
    const [deployer] = await ethers.getSigners();

    console.log('Deploying contracts with the account:', deployer.address);
    console.log('Account balance:', (await deployer.getBalance()).toString());

    const tokenAddress = argv.token ? `0x${argv.token}` : env.TOKEN_ADDRESS;
    const MEIToken = await ethers.getContractAt('MEIToken', tokenAddress, deployer);  

    const contractFileName = 'contracts/REITContract.sol:REITContract';

    console.log(`Deploying ${contractFileName}...`);
    const NFTContract = await ethers.getContractFactory(contractFileName);
    const contract = await NFTContract.deploy(tokenAddress, env.OPENING_TIME, env.CLOSING_TIME);
    await contract.deployed();
    
    console.log('Private sale contract address:', contract.address);      
  });

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    dev: {
      url: 'http://localhost:8545',
      accounts: [
        '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d', 
        '0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1',
        '0x6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c',
        '0x646f1ce2fdad0e6deeeb5c7e8e5543bdde65e86029e2fd9fc169899c440a7913',
        '0xadd53f9a7e588d003326d1cbf9e4a43c061aadd9bc938c843a79e7b4fd2ad743',
        '0x395df67f0c2d2d9fe1ad08d1bc8b6627011959b79c53d7dd6a3536a33ab8a4fd'
      ]
    },
    testnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      accounts: [secret.testnet],
      chainId: 97
    },    
    mainnet: {
      url: 'https://bsc-dataseed1.binance.org',
      accounts: [secret.mainnet],
      chainId: 56
    },    

    // Reserved
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      accounts: [secret.testnet],
      chainId: 4
    },
    
    ropsten: {
      url: 'https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      accounts: [secret.testnet],
      chainId: 3
    }    
  },
  solidity: {
    version: '0.8.4',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
};
