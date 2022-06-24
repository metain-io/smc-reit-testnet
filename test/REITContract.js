const moment = require('moment');
const { expect, use } = require('chai');
const { solidity } = require('ethereum-waffle');

const env = require('../env.json')['dev'];

use(solidity);

const TEST_REIT_AMOUNT = 200000;
const TEST_REIT_UNIT_PRICE = ethers.utils.parseEther('10');
const TEST_SHARE_HOLDER_FUND = ethers.utils.parseEther('100000');
const TEST_SHARES_TO_BUY_0 = 100;
const TEST_SHARES_TO_BUY_1 = 101;
const TEST_SHARES_TO_BUY_2 = 102;
const TEST_SHARES_TO_BUY_3 = 103;
const TEST_SHARES_TO_BUY_4 = 104;
const TEST_SHARES_TO_BUY_5 = 105;
const TEST_SHARES_TO_BUY_6 = 106;
const TEST_SHARES_TO_BUY_7 = 107;

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
const NFT_TRANSFER_AMOUNT = 9;

let IPOContract;
let IPOContractForShareholder = [];

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);  
}

console.log("\n--------- TEST FULL CASES ---------");

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

describe('Buying IPO', function () {

  // it('User 0: KYC => buy NFT => claim NFT', async function () {
  //   console.log(`\nUser 0: KYC => buy NFT => claim NFT`);
  //   // transfer USDT for User
  //   await USDContract.transfer(shareholder[0].address, TEST_SHARE_HOLDER_FUND);
  //   // allow IPOContract get USDT from user
  //   await USDContractForShareholder[0].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);

  //   // KYC user
  //   await NFTContract.addToKYC(shareholder[0].address);

  //   // buy NFT with USDT
  //   await IPOContractForShareholder[0].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_0);

  //   // check NFT baland after buy
  //   let balance = await NFTContract.balanceOf(shareholder[0].address, NFT_ID);
  //   console.log(`User 0: balance after buy: ${balance}`);

  //   // check NFT pending baland after buy
  //   let pendingBalance = await IPOContract.getPendingBalances(shareholder[0].address, 1);
  //   console.log(`User 0: pending Balance after buy: ${pendingBalance}`);

  //   expect(balance).equal(TEST_SHARES_TO_BUY_1);

  // });

  // it('User 1: buy NFT without KYC => KYC => claim NFT', async function () {
  //   console.log(`\nUser 1: buy NFT without KYC => KYC => claim NFT`);    
  //   // transfer USDT for User
  //   await USDContract.transfer(shareholder[1].address, TEST_SHARE_HOLDER_FUND);
  //   // allow IPOContract get USDT from user
  //   await USDContractForShareholder[1].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);

  //   // buy NFT with USDT
  //   await IPOContractForShareholder[1].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_1);

  //   // check NFT baland after buy
  //   let balance = await NFTContract.balanceOf(shareholder[1].address, NFT_ID);
  //   console.log(`User 1: balance after buy: ${balance}`);

  //   // check NFT pending baland after buy
  //   let pendingBalance = await IPOContract.getPendingBalances(shareholder[1].address, NFT_ID);
  //   console.log(`User 1: pendingBalance after buy: ${pendingBalance}`);

  //   // KYC user
  //   await NFTContract.addToKYC(shareholder[1].address);

  //   // user clam NFT from NFT contract
  //   await IPOContractForShareholder[1].claimPendingBalances(NFT_ID);

  //   // check NFT baland after KYC-Claim
  //   balance = await NFTContract.balanceOf(shareholder[1].address, NFT_ID);
  //   console.log(`User 1: balance after KYC-Claim: ${balance}`);

  //   // check NFT pending baland after KYC-Claim
  //   pendingBalance = await IPOContract.getPendingBalances(shareholder[1].address, NFT_ID);
  //   console.log(`User 1: pendingBalance after KYC-Claim: ${pendingBalance}`);

  //   expect(balance).equal(TEST_SHARES_TO_BUY_1);
  // });

  // it('User 2: try to claim NFT without buy/KYC', async function () {
  //   console.log(`\nUser 2: try to claim NFT without buy/KYC`);    
  //   let error;
  //   try {
  //     // user clam NFT from NFT contract
  //     await IPOContractForShareholder[2].claimPendingBalances(1);
  //   } catch(ex) {
  //     console.log(`User 2: ex: ${ex}`);
  //     error = ex;
  //   }
  //   expect(error);
  // });

  // it('User 2: KYC => try to claim NFT without buy', async function () {
  //   console.log(`\nUser 2: KYC => try to claim NFT without buy`);    
  //   let error;
  //   try {
  //     // KYC user
  //     await NFTContract.addToKYC(shareholder[2].address);
  //     // user clam NFT from NFT contract
  //     await IPOContractForShareholder[2].claimPendingBalances(1);
  //   } catch(ex) {
  //     console.log(`User 2: ex: ${ex}`);
  //     error = ex;
  //   }
  //   expect(error);
  // });

  it('User 2: KYC => buy NFT => Admin pay/unlock Dividend => buy more NFT => => Admin pay/unlock Dividend => claim Devidend', async function () {
    console.log(`\nUser 2: KYC => buy NFT => Admin pay/unlock Dividend => buy more NFT => => Admin pay/unlock Dividend => claim Devidend`);    
    // transfer USDT for User
    await USDContract.transfer(shareholder[2].address, TEST_SHARE_HOLDER_FUND);
    // allow IPOContract get USDT from user
    await USDContractForShareholder[2].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);

    // KYC user
    await NFTContract.addToKYC(shareholder[2].address);

    // buy NFT with USDT
    await IPOContractForShareholder[2].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_2);

    // check NFT balance after buy
    let balance = await NFTContract.balanceOf(shareholder[2].address, NFT_ID);
    console.log(`User 2: NFT balance after buy: ${balance}`);

    // Asset manager pays dividend, each NFT will receive $2
    // allow NFTContract get USDT from USDContract
    await USDContract.increaseAllowance(NFTContract.address, ethers.utils.parseEther('1000000'));
    // Admin give Dividends for NFT
    await NFTContract.payDividends(NFT_ID, ethers.utils.parseEther('100000'));
    // Admin unlock Dividends fund month 0 and set Dividends for per user 
    await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther('2'), 0);

    // User get Dividends info of user
    const shareholderDividend = await NFTContractForShareholder[2].getTotalClaimableBenefit(NFT_ID);
    console.log(`User 2: Dividends info: ${shareholderDividend} USD`);

    // buy NFT with USDT again
    await IPOContractForShareholder[2].purchaseWithToken('USDT', 1, TEST_SHARES_TO_BUY_2);
    // Admin unlock Dividends fund this month 1 and set Dividends for per user 
    await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther('1'), 1);

    // check NFT balance after buy again
    let newBalance = await NFTContract.balanceOf(shareholder[2].address, NFT_ID);
    console.log(`User 2: new NFT Balance after buy again: ${newBalance}`);

    // now get new Dividends info of user
    const newShareholderDividend = await NFTContractForShareholder[2].getTotalClaimableBenefit(1);
    console.log(`User 2: new Dividends info: ${newShareholderDividend} USD`);

    const usdBalance1 = BigInt(await USDContract.balanceOf(shareholder[2].address));
    console.log(`User 2: USD balance before claim: ${usdBalance1} USD`);

    // user claim dividend money
    await NFTContractForShareholder[2].claimBenefit(1);

    const usdBalance2 = BigInt(await USDContract.balanceOf(shareholder[2].address));
    console.log(`User 2: USD balance after claim: ${usdBalance2} USD`);

    const claimCount = BigInt(usdBalance2 - usdBalance1);
    console.log(`User 2: USD claimed: ${claimCount}`);

    expect(claimCount).equal(newShareholderDividend);
  });

  it('User 3: KYC => buy NFT => transfer NFT to User 4 (not KYC)=> check Devidend info', async function () {
    console.log(`\nUser 3: KYC => buy NFT => transfer NFT to User 4 (not KYC)=> check Devidend info`);    
    // transfer USDT for User
    await USDContract.transfer(shareholder[3].address, TEST_SHARE_HOLDER_FUND);
    // allow IPOContract get USDT from user
    await USDContractForShareholder[3].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);

    // KYC user
    await NFTContract.addToKYC(shareholder[3].address);

    // buy NFT with USDT
    await IPOContractForShareholder[3].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_3);

    // check NFT balance after buy
    let NFTbalance_user3 = await NFTContract.balanceOf(shareholder[3].address, NFT_ID);
    console.log(`User 3: NFT balance after buy: ${NFTbalance_user3}`);

    // transfer NFT from user 3 to user 4
    // await NFTContractForCreator.safeTransferFrom(shareholder[3].address, shareholder[4].address, NFT_ID, NFT_TRANSFER_AMOUNT, [])

    // check NFT balance after Transfer
    NFTbalance_user3 = await NFTContract.balanceOf(shareholder[3].address, NFT_ID);
    console.log(`User 3: NFT balance after transfer: ${NFTbalance_user3}`);
    let NFTbalance_user4 = await NFTContract.balanceOf(shareholder[4].address, NFT_ID);
    console.log(`User 4: NFT balance after transfer: ${NFTbalance_user4}`);

    // // User get Dividends info of user
    // const shareholderDividend = await NFTContractForShareholder[3].getTotalClaimableBenefit(1);
    // console.log(`User 3: Dividends info: ${shareholderDividend} USD`);

    expect(NFTbalance_user3, NFTbalance_user4)
  });

});


