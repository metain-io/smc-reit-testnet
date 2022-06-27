const moment = require('moment');
const { expect, use } = require('chai');
const { solidity } = require('ethereum-waffle');

const env = require('../env.json')['dev'];

use(solidity);

const TEST_REIT_AMOUNT = 200000;
const TEST_REIT_UNIT_PRICE = ethers.utils.parseEther('10');
const TEST_SHARE_HOLDER_FUND = ethers.utils.parseEther('100000');
const TEST_BUY_NFT_MIN = 100;
const TEST_BUY_NFT_MAX = 1000;
const TEST_DIVIDEND_MIN = 1;
const TEST_DIVIDEND_MAX = 10;
let TEST_NFT_SUM = 0;
let TEST_DIVIDEND_SUM = 0;
let TEST_USER_CLAIM_SUM = 0;

const TEST_REIT_DATA_URL = "ipfs://QmZ485APXNEhzLAtXccy5S78nMg83xBYJYXPSKtRVo8wy8";

// const [governor, creator, shareholder1, shareholder2, shareholder3] = await ethers.getSigners();
let governor;
let creator;
let shareholder = [];
const SHAREHOLDER_COUNT = 8;

let USDContract;
let USDContractForShareholder = [];

let NFTContract;
let NFTContractForCreator;
let NFTContractForShareholder = [];
const NFT_ID = 1;
const NFT_TRANSFER_AMOUNT = 10;

let IPOContract;
let IPOContractForShareholder = [];

const TEST_MONTHS = 24;

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);  
}

console.log("\x1b[33m%s\x1b[0m", "\n================== NFT/IPO RAMDOM TEST ==================");

describe('Deploy contracts', function () {
  it('Init Accounts', async function () {    
    // const [governor, creator, shareholder1, shareholder2, shareholder3, shareholder4] = await ethers.getSigners();
    const accounts = await ethers.getSigners();
    governor = accounts[0];
    creator = accounts[1];
    for (let i = 2; i < SHAREHOLDER_COUNT+2; ++i) {
      shareholder.push(accounts[i]);
    }
    expect(governor,creator,shareholder);
  });

  it('USDM', async function () {
    const USDFactory = await ethers.getContractFactory('USDMToken', governor);
    USDContract = await USDFactory.deploy('USDT', 'Mock USDT');
    await USDContract.deployed();

    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      const contract = await attachContractForSigner('USDMToken', shareholder[i], USDContract.address);
      USDContractForShareholder.push(contract);
    }
    expect(USDContract.address);
  });

  it('NFT', async function () {
    const NFTFactory = await ethers.getContractFactory('REITNFT', governor);
    NFTContract = await upgrades.deployProxy(NFTFactory, [
      "Metain REIT",
      "MREIT",
      "ipfs://Qme41Gw4qAttT7ZB2o6KVjYxu5LFMihG9aiZvMQLkhPjB3"
    ]);
    await NFTContract.deployed();

    NFTContractForCreator = await attachContractForSigner('REITNFT', creator, NFTContract.address);

    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      const contract = await attachContractForSigner('REITNFT', shareholder[i], NFTContract.address);
      NFTContractForShareholder.push(contract);
    }

    expect(NFTContract.address);
  });

  it('IPO', async function () {
    const IPOFactory = await ethers.getContractFactory('REITIPO', governor);
    IPOContract = await upgrades.deployProxy(IPOFactory, [
      NFTContract.address
    ]);
    await IPOContract.deployed();
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      const contract = await attachContractForSigner('REITIPO', shareholder[i], IPOContract.address);
      IPOContractForShareholder.push(contract);
    }
    expect(IPOContract.address);
  });
});

describe('Initiate REIT Opportunity Trust', function () {
  it('Create NFT Trust', async function () {
    await NFTContract.createREIT(creator.address, TEST_REIT_AMOUNT, TEST_REIT_DATA_URL, USDContract.address, []);
    await NFTContractForCreator.setIPOContract(NFT_ID, IPOContract.address);    
    const ipoContractAddress = await NFTContract.getIPOContract(1);
    expect(ipoContractAddress).equal(IPOContract.address);
  });

  it('Setup NFT Trust', async function () {
    await IPOContract.allowPayableToken('USDT', USDContract.address);
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      await IPOContract.addToWhitelisted(shareholder[i].address);
    }
    
    const now = Math.floor(Date.now() / 1000);
    await NFTContractForCreator.initiate(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, 2);    
    await NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, NFT_ID, TEST_REIT_AMOUNT, [])
    const ipoBalance = await NFTContract.balanceOf(IPOContract.address, NFT_ID);
    expect(ipoBalance).equal(TEST_REIT_AMOUNT);
  });
});

// The Timeout for a test case is 40000ms, so we need perform the test in many steps
describe('NFT/IPO RAMDOM TEST', function () {

  it('KYC => BUY NFT', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== KYC => BUY NFT =========`);
    TEST_NFT_SUM = 0;
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      // transfer USDT for Users    
      await USDContract.transfer(shareholder[i].address, TEST_SHARE_HOLDER_FUND);
      // allow IPOContract get USDT from users
      await USDContractForShareholder[i].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);
      // KYC users
      await NFTContract.addToKYC(shareholder[i].address);

      // buy NFT with USDT
      let NFT_AMOUNT = Math.floor(Math.random() * (TEST_BUY_NFT_MAX - TEST_BUY_NFT_MIN)) + TEST_BUY_NFT_MIN;
      await IPOContractForShareholder[i].purchaseWithToken('USDT', NFT_ID, NFT_AMOUNT);

      // check NFT baland after buy
      let balance = await NFTContract.balanceOf(shareholder[i].address, NFT_ID);
      TEST_NFT_SUM += parseInt(balance);
      console.log(`User ${i}: NFT balance: ${balance}`);
    }
    console.log(`NFT_SUM: ${TEST_NFT_SUM}`);
    expect(TEST_NFT_SUM).not.equal(0);
  });

  it('PAY/UNLOCK DIVIDEND', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== PAY/UNLOCK DIVIDEND - ${TEST_MONTHS} MONTHS =========`);
    TEST_DIVIDEND_SUM = 0;
    // allow NFTContract get USDT from USDContract
    await USDContract.increaseAllowance(NFTContract.address, ethers.utils.parseEther('100000000'));
    // Admin give Dividends for NFT
    await NFTContract.payDividends(NFT_ID, ethers.utils.parseEther('100000000'));

    for (let i = 0; i < TEST_MONTHS; ++i) {
      let DIVIDEND_AMOUNT = Math.floor(Math.random() * (TEST_DIVIDEND_MAX - TEST_DIVIDEND_MIN)) + TEST_DIVIDEND_MIN;
      // Admin unlock Dividends fund for monthS and set Dividends for per user 
      await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther(DIVIDEND_AMOUNT.toString()), i);
      TEST_DIVIDEND_SUM += parseInt(DIVIDEND_AMOUNT*TEST_NFT_SUM);
      console.log(`DIVIDEND_AMOUNT of month ${i}: ${DIVIDEND_AMOUNT} USD`);
    }
    console.log(`TEST_DIVIDEND_SUM after ${TEST_MONTHS} months: ${TEST_DIVIDEND_SUM} USD`)

    expect(TEST_DIVIDEND_SUM).not.equal(0);
  });

  // Because the Timeout, only claim dividend from 4 users
  it('USER CLAIM DIVIDEND 1', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== CLAIM DIVIDEND FROM USER 0, 1, 2, 3 =========`);

    const beginUser = 0;
    const lastUser = 4;
    for (let i = beginUser; i < lastUser; ++i) {
      // USD balance before claim
      let usdBalance = parseInt(ethers.utils.formatEther(await USDContract.balanceOf(shareholder[i].address)));
    
      // user claim dividend money
      await NFTContractForShareholder[i].claimBenefit(NFT_ID);
 
      // USD balance before claim
      let usdBalance_afterClaim = parseInt(ethers.utils.formatEther(await USDContract.balanceOf(shareholder[i].address)));

      // dividend money
      const claimCount = usdBalance_afterClaim - usdBalance;
      console.log(`User ${i} claimCount: ${claimCount}`);
    
      TEST_USER_CLAIM_SUM += claimCount;
    }
    console.log(`TEST_USER_CLAIM_SUM: ${TEST_USER_CLAIM_SUM} USD`)
    console.log(`TEST_DIVIDEND_SUM: ${TEST_DIVIDEND_SUM} USD`)

    expect(TEST_USER_CLAIM_SUM).not.equal(0);
  });

  // Because the Timeout, only claim dividend from 4 users
  it('USER CLAIM DIVIDEND 1', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== CLAIM DIVIDEND FROM USER 4, 5, 6, 7 =========`);

    const beginUser = 4;
    const lastUser = SHAREHOLDER_COUNT;
    for (let i = beginUser; i < lastUser; ++i) {
      // USD balance before claim
      let usdBalance = parseInt(ethers.utils.formatEther(await USDContract.balanceOf(shareholder[i].address)));
    
      // user claim dividend money
      await NFTContractForShareholder[i].claimBenefit(NFT_ID);

      // USD balance before claim
      let usdBalance_afterClaim = parseInt(ethers.utils.formatEther(await USDContract.balanceOf(shareholder[i].address)));

      // dividend money
      const claimCount = usdBalance_afterClaim - usdBalance;
      console.log(`User ${i} claimCount: ${claimCount}`);
    
      TEST_USER_CLAIM_SUM += claimCount;
    }
    console.log(`TEST_USER_CLAIM_SUM: ${TEST_USER_CLAIM_SUM} USD`)
    console.log(`TEST_DIVIDEND_SUM: ${TEST_DIVIDEND_SUM} USD`)

    expect(TEST_USER_CLAIM_SUM).equal(TEST_DIVIDEND_SUM);
  });

});


