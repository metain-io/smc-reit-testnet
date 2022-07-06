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
const NFT_TRANSFER_AMOUNT = 10;

let IPOContract;
let IPOContractForShareholder = [];

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);  
}

console.log("\x1b[33m%s\x1b[0m", "\n================== TEST FULL CASES ==================");

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
    const ipoContractAddress = await NFTContract.getIPOContract(NFT_ID);
    expect(ipoContractAddress).equal(IPOContract.address);
  });

  it('Setup NFT Trust', async function () {
    await IPOContract.allowPayableToken('USDT', USDContract.address);
    // for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
    //   await IPOContract.addToWhitelisted(shareholder[i].address);
    // }
    
    const now = Math.floor(Date.now() / 1000);
    await NFTContractForCreator.initiateREIT(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, 2);    
    await NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, NFT_ID, TEST_REIT_AMOUNT, [])
    const ipoBalance = await NFTContract.balanceOf(IPOContract.address, NFT_ID);
    expect(ipoBalance).equal(TEST_REIT_AMOUNT);
  });
});

describe('Buying IPO', function () {

  it('User 0: KYC => buy NFT => claim NFT', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 0: KYC => buy NFT => claim NFT`);
    // transfer USDT for User
    await USDContract.transfer(shareholder[0].address, TEST_SHARE_HOLDER_FUND);
    // allow IPOContract get USDT from user
    await USDContractForShareholder[0].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);

    // KYC user
    await NFTContract.addToKYC(shareholder[0].address);

    // buy NFT with USDT
    await IPOContractForShareholder[0].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_0);

    // check NFT baland after buy
    let balance = await NFTContract.balanceOf(shareholder[0].address, NFT_ID);
    console.log(`User 0: balance after buy: ${balance}`);

    // check NFT pending baland after buy
    let pendingBalance = await IPOContract.getPendingBalances(shareholder[0].address, 1);
    console.log(`User 0: pending Balance after buy: ${pendingBalance}`);

    expect(balance).equal(TEST_SHARES_TO_BUY_0);

  });

  it('User 1: buy NFT without KYC => KYC => claim NFT', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 1: buy NFT without KYC => KYC => claim NFT`);    
    // transfer USDT for User
    await USDContract.transfer(shareholder[1].address, TEST_SHARE_HOLDER_FUND);
    // allow IPOContract get USDT from user
    await USDContractForShareholder[1].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);

    // buy NFT with USDT
    await IPOContractForShareholder[1].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_1);

    // check NFT baland after buy
    let balance = await NFTContract.balanceOf(shareholder[1].address, NFT_ID);
    console.log(`User 1: balance after buy: ${balance}`);

    // check NFT pending baland after buy
    let pendingBalance = await IPOContract.getPendingBalances(shareholder[1].address, NFT_ID);
    console.log(`User 1: pendingBalance after buy: ${pendingBalance}`);

    // KYC user
    await NFTContract.addToKYC(shareholder[1].address);

    // user clam NFT from NFT contract
    await IPOContractForShareholder[1].claimPendingBalances(NFT_ID);

    // check NFT baland after KYC-Claim
    balance = await NFTContract.balanceOf(shareholder[1].address, NFT_ID);
    console.log(`User 1: balance after KYC-Claim: ${balance}`);

    // check NFT pending baland after KYC-Claim
    pendingBalance = await IPOContract.getPendingBalances(shareholder[1].address, NFT_ID);
    console.log(`User 1: pendingBalance after KYC-Claim: ${pendingBalance}`);

    expect(balance).equal(TEST_SHARES_TO_BUY_1);
  });

  it('User 2: try to claim NFT without buy/KYC', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 2: try to claim NFT without buy/KYC`);    
    let error;
    try {
      // user clam NFT from IPO contract
      await IPOContractForShareholder[2].claimPendingBalances(NFT_ID);
    } catch(ex) {
      console.log(`User 2: ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it('User 2: KYC => try to claim NFT without buy', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 2: KYC => try to claim NFT without buy`);    
    let error;
    try {
      // KYC user
      await NFTContract.addToKYC(shareholder[2].address);
      // user clam NFT from IPO contract
      await IPOContractForShareholder[2].claimPendingBalances(NFT_ID);
    } catch(ex) {
      console.log(`User 2: ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it('User 2: KYC => buy NFT => try to claim NFT before Admin pay/unlock Dividend', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 2: KYC => buy NFT => try to claim NFT before Admin pay/unlock Dividend`);    
    let error;
    try {
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

      // User get Dividends info of user
      const shareholderDividend = await NFTContractForShareholder[2].getTotalClaimableDividends(NFT_ID);
      console.log(`User 2: Dividends info: ${shareholderDividend} USD`);

          // user claim dividend money
      await NFTContractForShareholder[2].claimDividend(NFT_ID);

    } catch(ex) {
      console.log(`User 2: ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it('User 2: KYC => buy NFT => Admin pay/unlock Dividend => buy more NFT => Admin pay/unlock Dividend => claim Dividend', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 2: KYC => buy NFT => Admin pay/unlock Dividend => buy more NFT => Admin pay/unlock Dividend => claim Dividend`);    
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
    await NFTContract.fundREITVault(NFT_ID, ethers.utils.parseEther('100000'));
    // Admin unlock Dividends fund for month 0 and set Dividends for per user 
    await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther('2'), 0);

    // User get Dividends info of user
    const shareholderDividend = await NFTContractForShareholder[2].getTotalClaimableDividends(NFT_ID);
    console.log(`User 2: Dividends info: ${shareholderDividend} USD`);

    // buy NFT with USDT again
    await IPOContractForShareholder[2].purchaseWithToken('USDT', 1, TEST_SHARES_TO_BUY_2);

    // Admin unlock Dividends fund for month 1 and set Dividends for per user, each NFT will receive $1
    await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther('1'), 1);

    // check NFT balance after buy again
    let newBalance = await NFTContract.balanceOf(shareholder[2].address, NFT_ID);
    console.log(`User 2: new NFT Balance after buy again: ${newBalance}`);

    // now get new Dividends info of user
    const newShareholderDividend = await NFTContractForShareholder[2].getTotalClaimableDividends(NFT_ID);
    console.log(`User 2: new Dividends info: ${newShareholderDividend} USD`);

    const usdBalance1 = BigInt(await USDContract.balanceOf(shareholder[2].address));
    console.log(`User 2: USD balance before claim: ${usdBalance1} USD`);

    // user claim dividend money
    await NFTContractForShareholder[2].claimDividend(NFT_ID);

    const usdBalance2 = BigInt(await USDContract.balanceOf(shareholder[2].address));
    console.log(`User 2: USD balance after claim: ${usdBalance2} USD`);

    const claimCount = BigInt(usdBalance2 - usdBalance1);
    console.log(`User 2: USD claimed: ${claimCount}`);

    expect(claimCount).equal(newShareholderDividend);
  });

  it('User 3: KYC => buy NFT => transfer NFT to User 4 => register => Admin pay/unlock Dividend => check Dividend info', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 3: KYC => buy NFT => transfer NFT to User 4 => register => Admin pay/unlock Dividend => check Dividend info`);    
    // transfer USDT for User
    await USDContract.transfer(shareholder[3].address, TEST_SHARE_HOLDER_FUND);
    await USDContract.transfer(shareholder[4].address, TEST_SHARE_HOLDER_FUND);
    // allow IPOContract and NFTContract get USDT from user
    await USDContractForShareholder[3].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);
    await USDContractForShareholder[3].increaseAllowance(NFTContract.address, TEST_SHARE_HOLDER_FUND);
    await USDContractForShareholder[4].increaseAllowance(NFTContract.address, TEST_SHARE_HOLDER_FUND);

    // KYC user
    await NFTContract.addToKYC(shareholder[3].address);
    await NFTContract.addToKYC(shareholder[4].address);

    // buy NFT with USDT
    await IPOContractForShareholder[3].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_3);

    // check NFT balance after buy
    let NFTbalance_user3 = await NFTContract.balanceOf(shareholder[3].address, NFT_ID);
    console.log(`User 3: NFT balance after buy: ${NFTbalance_user3}`);

    // transfer NFT from user 3 to user 4
    await NFTContractForShareholder[3].safeTransferFrom(shareholder[3].address, shareholder[4].address, NFT_ID, NFT_TRANSFER_AMOUNT, [])

    // check NFT balance after Transfer
    NFTbalance_user3 = await NFTContract.balanceOf(shareholder[3].address, NFT_ID);
    console.log(`User 3: NFT balance after transfer: ${NFTbalance_user3}`);
    let NFTbalance_user4 = await NFTContract.balanceOf(shareholder[4].address, NFT_ID);
    console.log(`User 4: NFT balance after transfer: ${NFTbalance_user4}`);

    // register NFT after transfer
    await NFTContractForShareholder[4].redeemLockedBalances(NFT_ID);

    // check NFT balance after register
    NFTbalance_user4 = await NFTContract.balanceOf(shareholder[4].address, NFT_ID);
    console.log(`User 4: NFT balance after register: ${NFTbalance_user4}`);

    // Asset manager pays dividend, each NFT will receive $1
    // allow NFTContract get USDT from USDContract
    await USDContract.increaseAllowance(NFTContract.address, ethers.utils.parseEther('1000000'));
    // Admin give Dividends for NFT
    await NFTContract.fundREITVault(NFT_ID, ethers.utils.parseEther('100000'));
    // Admin unlock Dividends fund for month 2 and set Dividends for per user 
    await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther('1'), 2);

    // check Dividends info of user
    const shareholderDividend_user3 = await NFTContractForShareholder[3].getTotalClaimableDividends(NFT_ID);
    console.log(`User 3: Dividends info: ${shareholderDividend_user3} USD`);
    const shareholderDividend_user4 = await NFTContractForShareholder[4].getTotalClaimableDividends(NFT_ID);
    console.log(`User 4: Dividends info: ${shareholderDividend_user4} USD`);

    expect(shareholderDividend_user4).not.equal(0)
  });

  it('User 5: KYC => buy NFT => Unlock Dividend 1 => buy more NFT => transfer NFT to User 6 => Unlock Dividend 2 => register => check Dividend info => claim Dividend', async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nUser 5: KYC => buy NFT => Unlock Dividend 1 => buy more NFT => transfer NFT to User 6 => Unlock Dividend 2 => register => check Dividend info => claim Dividend`);    
    // transfer USDT for User
    await USDContract.transfer(shareholder[5].address, TEST_SHARE_HOLDER_FUND);
    await USDContract.transfer(shareholder[6].address, TEST_SHARE_HOLDER_FUND);
    // allow IPOContract get USDT from user
    await USDContractForShareholder[5].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);
    await USDContractForShareholder[5].increaseAllowance(NFTContract.address, TEST_SHARE_HOLDER_FUND);
    await USDContractForShareholder[6].increaseAllowance(NFTContract.address, TEST_SHARE_HOLDER_FUND);

    // KYC user
    await NFTContract.addToKYC(shareholder[5].address);
    await NFTContract.addToKYC(shareholder[6].address);

    // buy NFT with USDT
    await IPOContractForShareholder[5].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_4);

    // Asset manager pays dividend, each NFT will receive $1
    // allow NFTContract get USDT from USDContract
    await USDContract.increaseAllowance(NFTContract.address, ethers.utils.parseEther('1000000'));
    // Admin give Dividends for NFT
    await NFTContract.fundREITVault(NFT_ID, ethers.utils.parseEther('100000'));
    // Admin unlock Dividends fund for month 3 and set Dividends for per user 
    await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther('1'), 3);

    // buy more NFT with USDT
    await IPOContractForShareholder[5].purchaseWithToken('USDT', NFT_ID, TEST_SHARES_TO_BUY_4);

    // check NFT balance after buy
    let NFTbalance_user5 = await NFTContract.balanceOf(shareholder[5].address, NFT_ID);
    console.log(`User 5: NFT balance after buy: ${NFTbalance_user5}`);

    // User get Dividends info
    let getTotalClaimableDividends_user5 = await NFTContractForShareholder[5].getTotalClaimableDividends(NFT_ID);
    console.log(`User 5: getTotalClaimableDividends: ${getTotalClaimableDividends_user5} USD`);

    // transfer NFT from user 5 to user 6
    await NFTContractForShareholder[5].safeTransferFrom(shareholder[5].address, shareholder[6].address, NFT_ID, NFT_TRANSFER_AMOUNT, [])

    // Admin unlock Dividends fund for month 4 and set Dividends for per user, each NFT will receive $1
    await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther('1'), 4);

    // check NFT balance after Transfer
    NFTbalance_user5 = await NFTContract.balanceOf(shareholder[5].address, NFT_ID);
    console.log(`User 5: NFT balance after transfer: ${NFTbalance_user5}`);
    let NFTbalance_user6 = await NFTContract.balanceOf(shareholder[6].address, NFT_ID);
    console.log(`User 6: NFT balance after transfer: ${NFTbalance_user6}`);

    let NFTlockingBalance_user6 = await NFTContract.lockingBalanceOf(shareholder[6].address, NFT_ID);
    console.log(`User 6: NFT locking balance after transfer: ${NFTlockingBalance_user6}`);
    let getTotalClaimableDividends_user6 = await NFTContractForShareholder[6].getTotalClaimableDividends(NFT_ID);
    console.log(`User 6: getTotalClaimableDividends after transfer: ${getTotalClaimableDividends_user6} USD`);
    let getLockedYieldDividends_user6 = await NFTContractForShareholder[6].getLockedYieldDividends(NFT_ID);
    console.log(`User 6: getLockedYieldDividends after transfer: ${getLockedYieldDividends_user6} USD`);

    // register NFT after transfer
    await NFTContractForShareholder[6].redeemLockedBalances(NFT_ID);

    // check NFT balance after register
    NFTbalance_user6 = await NFTContract.balanceOf(shareholder[6].address, NFT_ID);
    console.log(`User 6: NFT balance after register: ${NFTbalance_user6}`);

    getTotalClaimableDividends_user6 = await NFTContractForShareholder[6].getTotalClaimableDividends(NFT_ID);
    console.log(`User 6: getTotalClaimableDividends after register: ${getTotalClaimableDividends_user6} USD`);
    getLockedYieldDividends_user6 = await NFTContractForShareholder[6].getLockedYieldDividends(NFT_ID);
    console.log(`User 6: getLockedYieldDividends after register: ${getLockedYieldDividends_user6} USD`);

    // USD balance before claim
    const usdBalance_user5 = BigInt(await USDContract.balanceOf(shareholder[5].address));
    const usdBalance_user6 = BigInt(await USDContract.balanceOf(shareholder[6].address));
    console.log(`User 5: USD balance before claim: ${usdBalance_user5} USD`);
    console.log(`User 6: USD balance before claim: ${usdBalance_user6} USD`);

    // user claim dividend money
    await NFTContractForShareholder[5].claimDividend(NFT_ID);
    await NFTContractForShareholder[6].claimDividend(NFT_ID);

    // USD balance before claim
    const usdBalance_user5_claimed = BigInt(await USDContract.balanceOf(shareholder[5].address));
    const usdBalance_user6_claimed = BigInt(await USDContract.balanceOf(shareholder[6].address));
    console.log(`User 5: USD balance after claim: ${usdBalance_user5_claimed} USD`);
    console.log(`User 6: USD balance after claim: ${usdBalance_user6_claimed} USD`);

    const claimCount_user5 = BigInt(usdBalance_user5_claimed - usdBalance_user5);
    const claimCount_user6 = BigInt(usdBalance_user6_claimed - usdBalance_user6);
    console.log("\x1b[35m%s\x1b[0m", `User 5: USD claimed: ${claimCount_user5} USD`);
    console.log("\x1b[35m%s\x1b[0m", `User 6: USD claimed: ${claimCount_user6} USD`);

    // User get Dividends info - getClaimedYield
    let getClaimedYield_user5 = await NFTContractForShareholder[5].getClaimedYield(NFT_ID);
    console.log(`User 5: getClaimedYield: ${getClaimedYield_user5} USD`);
    let getClaimedYield_user6 = await NFTContractForShareholder[6].getClaimedYield(NFT_ID);
    console.log(`User 6: getClaimedYield: ${getClaimedYield_user6} USD`);

    resultTest = [claimCount_user5, claimCount_user6]
    expect(resultTest).not.contain(0)
  });


});


