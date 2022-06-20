const moment = require('moment');
const { expect, use } = require('chai');
const { solidity } = require('ethereum-waffle');

const env = require('../env.json')['dev'];

use(solidity);

// const [governor, creator, shareholder1, shareholder2, shareholder3] = await ethers.getSigners();

let USDContract;
let NFTContract;
let IPOContract;

let NFTContractForCreator;

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);  
}

describe('Deploy contracts', function () {  
  it('USDM', async function () {    
    const USDFactory = await ethers.getContractFactory('USDMToken', governor);
    USDContract = await USDFactory.deploy('USDT', 'Mock USDT');
    await USDContract.deployed();
    expect(USDContract.address);
  });

  it('NFT', async function () {
    const [governor, creator] = await ethers.getSigners();
    const NFTFactory = await ethers.getContractFactory('REITNFT', governor);
    NFTContract = await upgrades.deployProxy(NFTFactory, [
      "Metain REIT",
      "MREIT",
      "ipfs://Qme41Gw4qAttT7ZB2o6KVjYxu5LFMihG9aiZvMQLkhPjB3"
    ]);
    await NFTContract.deployed();

    NFTContractForCreator = await attachContractForSigner('REITNFT', creator)
    expect(NFTContract.address);
  });

  it('IPO', async function () {
    const [governor] = await ethers.getSigners();
    const IPOFactory = await ethers.getContractFactory('REITIPO', governor);
    IPOContract = await upgrades.deployProxy(IPOFactory, [
      NFTContract.address
    ]);
    await IPOContract.deployed();
    expect(IPOContract.address);
  });
});

describe('Initiate REIT Opportunity Trust', function () {
  it('Create NFT Trust', async function () {

  });
});
