const moment = require('moment');
const { expect, use } = require('chai');
const { solidity } = require('ethereum-waffle');

const env = require('../env.json')['dev'];

use(solidity);

const TEST_REIT_AMOUNT = 200000;
const TEST_REIT_UNIT_PRICE = ethers.utils.parseEther('10');
const TEST_SHARE_HOLDER_FUND = ethers.utils.parseEther('100000');
const TEST_SHARES_TO_BUY_1 = 101;

const TEST_REIT_DATA_URL = "ipfs://QmZ485APXNEhzLAtXccy5S78nMg83xBYJYXPSKtRVo8wy8";

// const [governor, creator, shareholder1, shareholder2, shareholder3] = await ethers.getSigners();

let USDContract;
let USDContractForShareholder1;

let NFTContract;
let NFTContractForCreator;

let IPOContract;
let IPOContractForShareholder1;

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);  
}

describe('Deploy contracts', function () {  
  it('USDM', async function () {    
    const [governor, creator, shareholder1] = await ethers.getSigners();
    const USDFactory = await ethers.getContractFactory('USDMToken', governor);
    USDContract = await USDFactory.deploy('USDT', 'Mock USDT');
    await USDContract.deployed();

    USDContractForShareholder1 = await attachContractForSigner('USDMToken', shareholder1, USDContract.address);
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

    NFTContractForCreator = await attachContractForSigner('REITNFT', creator, NFTContract.address);
    expect(NFTContract.address);
  });

  it('IPO', async function () {
    const [governor, creator, shareholder1] = await ethers.getSigners();
    const IPOFactory = await ethers.getContractFactory('REITIPO', governor);
    IPOContract = await upgrades.deployProxy(IPOFactory, [
      NFTContract.address
    ]);
    await IPOContract.deployed();

    IPOContractForShareholder1 = await attachContractForSigner('REITIPO', shareholder1, IPOContract.address);
    expect(IPOContract.address);
  });
});

describe('Initiate REIT Opportunity Trust', function () {
  it('Create NFT Trust', async function () {    
    const [governor, creator] = await ethers.getSigners();
    await NFTContract.createREIT(creator.address, TEST_REIT_AMOUNT, TEST_REIT_DATA_URL, USDContract.address, []);
    await NFTContractForCreator.setIPOContract(1, IPOContract.address);    
    const ipoContractAddress = await NFTContract.getIPOContract(1);
    expect(ipoContractAddress).equal(IPOContract.address);
  });

  it('Setup NFT Trust', async function () {
    const [governor, creator, shareholder1] = await ethers.getSigners();
    await IPOContract.allowPayableToken('USDT', USDContract.address);
    await IPOContract.addToWhitelisted(shareholder1.address);
    
    const now = Math.floor(Date.now() / 1000);
    await NFTContractForCreator.initiate(1, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, 2);    
    await NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, 1, TEST_REIT_AMOUNT, [])
    const ipoBalance = await NFTContract.registeredBalanceOf(IPOContract.address, 1);
    expect(ipoBalance).equal(TEST_REIT_AMOUNT);
  });
});

describe('Buying IPO', function () {
  
  it('Buy NFT without KYC', async function () {
    const [governor, creator, shareholder1] = await ethers.getSigners();

    await USDContract.transfer(shareholder1.address, TEST_SHARE_HOLDER_FUND);
    await USDContractForShareholder1.increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);

    await IPOContractForShareholder1.purchaseWithToken('USDT', 1, TEST_SHARES_TO_BUY_1);

    const b1 = await NFTContract.balanceOf(shareholder1.address, 1);
    const b2 = await IPOContract.getPendingBalances(shareholder1.address, 1);
    expect(b1).not.equal(b2);
  });

  it('Try to KYC and reclaim', async function () {
    const [governor, creator, shareholder1] = await ethers.getSigners();
    const pending = await IPOContract.getPendingBalances(shareholder1.address, 1);
    await NFTContract.addToKYC(shareholder1.address);
    await IPOContractForShareholder1.claimPendingBalances(1);
    const claimed = await NFTContract.registeredBalanceOf(shareholder1.address, 1);
    expect(pending).equal(claimed);
  });
});
