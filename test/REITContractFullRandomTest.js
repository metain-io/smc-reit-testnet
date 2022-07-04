const moment = require("moment");
const { expect, use } = require("chai");
const { solidity } = require("ethereum-waffle");

const env = require("../env.json")["dev"];

use(solidity);

const TEST_REIT_AMOUNT = 200000;
const TEST_REIT_UNIT_PRICE = ethers.utils.parseEther("10");
const TEST_SHARE_HOLDER_FUND = ethers.utils.parseEther("100000");
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
const NFT_TRANSFER_MIN = 10;
const NFT_TRANSFER_MAX = 100;

let IPOContract;
let IPOContractForShareholder = [];

const TEST_MONTHS = 12;

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);
}

console.log("\x1b[33m%s\x1b[0m", "\n================== NFT/IPO RAMDOM TEST ==================");

describe("Deploy contracts", function () {
  it("Init Accounts", async function () {
    // const [governor, creator, shareholder1, shareholder2, shareholder3, shareholder4] = await ethers.getSigners();
    const accounts = await ethers.getSigners();
    governor = accounts[0];
    creator = accounts[1];
    for (let i = 2; i < SHAREHOLDER_COUNT + 2; ++i) {
      shareholder.push(accounts[i]);
    }
    expect(governor, creator, shareholder);
  });

  it("USDM", async function () {
    const USDFactory = await ethers.getContractFactory("USDMToken", governor);
    USDContract = await USDFactory.deploy("USDT", "Mock USDT");
    await USDContract.deployed();

    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      const contract = await attachContractForSigner("USDMToken", shareholder[i], USDContract.address);
      USDContractForShareholder.push(contract);
    }
    expect(USDContract.address);
  });

  it("NFT", async function () {
    const NFTFactory = await ethers.getContractFactory("REITNFT", governor);
    NFTContract = await upgrades.deployProxy(NFTFactory, [
      "Metain REIT",
      "MREIT",
      "ipfs://Qme41Gw4qAttT7ZB2o6KVjYxu5LFMihG9aiZvMQLkhPjB3",
    ]);
    await NFTContract.deployed();

    NFTContractForCreator = await attachContractForSigner("REITNFT", creator, NFTContract.address);

    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      const contract = await attachContractForSigner("REITNFT", shareholder[i], NFTContract.address);
      NFTContractForShareholder.push(contract);
    }

    expect(NFTContract.address);
  });

  it("IPO", async function () {
    const IPOFactory = await ethers.getContractFactory("REITIPO", governor);
    IPOContract = await upgrades.deployProxy(IPOFactory, [NFTContract.address]);
    await IPOContract.deployed();
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      const contract = await attachContractForSigner("REITIPO", shareholder[i], IPOContract.address);
      IPOContractForShareholder.push(contract);
    }
    expect(IPOContract.address);
  });
});

describe("Initiate REIT Opportunity Trust", function () {
  it("Create NFT Trust", async function () {
    await NFTContract.createREIT(creator.address, TEST_REIT_AMOUNT, TEST_REIT_DATA_URL, USDContract.address, []);
    await NFTContractForCreator.setIPOContract(NFT_ID, IPOContract.address);
    const ipoContractAddress = await NFTContract.getIPOContract(1);
    expect(ipoContractAddress).equal(IPOContract.address);
  });

  it("Setup NFT Trust", async function () {
    await IPOContract.allowPayableToken("USDT", USDContract.address);
    // for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
    //   await IPOContract.addToWhitelisted(shareholder[i].address);
    // }

    const now = Math.floor(Date.now() / 1000);
    await NFTContractForCreator.initiate(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, 2);
    await NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, NFT_ID, TEST_REIT_AMOUNT, []);
    const ipoBalance = await NFTContract.balanceOf(IPOContract.address, NFT_ID);
    expect(ipoBalance).equal(TEST_REIT_AMOUNT);
  });
});

// The Timeout for a test case is 40000ms, so we need perform the test in many steps
describe("NFT/IPO RAMDOM TEST", function () {
  it("KYC => BUY NFT", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== KYC => BUY NFT =========`);
    TEST_NFT_SUM = 0;
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      // transfer USDT for Users
      await USDContract.transfer(shareholder[i].address, TEST_SHARE_HOLDER_FUND);
      // allow IPOContract get USDT from users
      await USDContractForShareholder[i].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);
      await USDContractForShareholder[i].increaseAllowance(NFTContract.address, TEST_SHARE_HOLDER_FUND);
      // KYC users
      await NFTContract.addToKYC(shareholder[i].address);

      // buy NFT with USDT
      let NFT_AMOUNT = Math.floor(Math.random() * (TEST_BUY_NFT_MAX - TEST_BUY_NFT_MIN)) + TEST_BUY_NFT_MIN;
      await IPOContractForShareholder[i].purchaseWithToken("USDT", NFT_ID, NFT_AMOUNT);

      // check NFT balance after buy
      let balance = await NFTContract.balanceOf(shareholder[i].address, NFT_ID);
      TEST_NFT_SUM += parseInt(balance);
      console.log(`User ${i}: NFT balance: ${balance}`);
    }
    console.log(`NFT_SUM: ${TEST_NFT_SUM}`);
    expect(TEST_NFT_SUM).not.equal(0);
  });

  it("PAY/UNLOCK DIVIDEND", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== PAY/UNLOCK DIVIDEND - ${TEST_MONTHS} MONTHS =========`);
    console.log("\x1b[33m%s\x1b[0m", `\nTransfer NFT => Unlock Dividend => check Dividen info => claim Dividen`);
    TEST_DIVIDEND_SUM = 0;
    // allow NFTContract get USDT from USDContract
    await USDContract.increaseAllowance(NFTContract.address, ethers.utils.parseEther("100000000"));
    // Admin give Dividends for NFT
    await NFTContract.payDividends(NFT_ID, ethers.utils.parseEther("100000000"));

    for (let i = 0; i < TEST_MONTHS; ++i) {
      // try transfer before Dividends
      let TRANSFER_FROM = Math.floor(Math.random() * (SHAREHOLDER_COUNT - 1));
      let TRANSFER_TO = Math.floor(Math.random() * (SHAREHOLDER_COUNT - 1));
      let TRANSFER_AMOUNT = Math.floor(Math.random() * (NFT_TRANSFER_MAX - NFT_TRANSFER_MIN)) + NFT_TRANSFER_MIN;
      let DIVIDEND_AMOUNT = Math.floor(Math.random() * (TEST_DIVIDEND_MAX - TEST_DIVIDEND_MIN)) + TEST_DIVIDEND_MIN;
      console.log("\x1b[34m%s\x1b[0m", `=== Month ${i}: DIVIDEND_AMOUNT: ${DIVIDEND_AMOUNT} USD ===`);

      let NFTlockingBalance = 0;
      try {
        // transfer NFT
        await NFTContractForShareholder[TRANSFER_FROM].safeTransferFrom(
          shareholder[TRANSFER_FROM].address,
          shareholder[TRANSFER_TO].address,
          NFT_ID,
          TRANSFER_AMOUNT,
          []
        );
        console.log(`Transfer SUCCESS: ${TRANSFER_AMOUNT} NFT from User ${TRANSFER_FROM} to User ${TRANSFER_TO}`);

        NFTlockingBalance = await NFTContract.lockingBalanceOf(shareholder[TRANSFER_TO].address, NFT_ID);
        console.log(`User  ${TRANSFER_TO}: NFT locking balance after transfer: ${NFTlockingBalance}`);
      } catch (error) {
        console.log("\x1b[35m%s\x1b[0m", `Transfer FAIL: ${TRANSFER_AMOUNT} NFT from User ${TRANSFER_FROM} to User ${TRANSFER_TO}`);
        console.log("\x1b[35m%s\x1b[0m", `Error: ${error}`);
      }

      // Admin unlock Dividends fund for monthS and set Dividends for per user
      await NFTContractForCreator.unlockDividendPerShare(
        NFT_ID,
        ethers.utils.parseEther(DIVIDEND_AMOUNT.toString()),
        i
      );
      TEST_DIVIDEND_SUM += parseInt(DIVIDEND_AMOUNT * TEST_NFT_SUM);
      console.log(`Unlocked DIVIDEND_AMOUNT: ${DIVIDEND_AMOUNT} USD`);

      // check Dividends info before registerBalances
      getLockedYieldDividends = parseInt(
        ethers.utils.formatEther(await NFTContractForShareholder[TRANSFER_TO].getLockedYieldDividends(NFT_ID))
      );
      console.log(`User ${TRANSFER_TO}: getLockedYieldDividends after Unlock Dividend: ${getLockedYieldDividends} USD`);

      dividendClaim = parseInt(
        ethers.utils.formatEther(await NFTContractForShareholder[TRANSFER_TO].getTotalClaimableBenefit(NFT_ID))
      );
      if (dividendClaim > 0) {
        console.log(`User ${TRANSFER_TO}: Try to claim ${dividendClaim} USD after Unlock Dividend`);
        // try to claim before registerBalances
        await NFTContractForShareholder[TRANSFER_TO].claimBenefit(NFT_ID);
        TEST_USER_CLAIM_SUM += dividendClaim;
      }

      if (NFTlockingBalance > 0) {
        // register NFT after transfer success
        await NFTContractForShareholder[TRANSFER_TO].registerBalances(NFT_ID);
      }
    }
    console.log("\x1b[33m%s\x1b[0m", `TEST_DIVIDEND_SUM after ${TEST_MONTHS} months: ${TEST_DIVIDEND_SUM} USD`);
    console.log("\x1b[33m%s\x1b[0m", `TEST_USER_CLAIM_SUM: ${TEST_USER_CLAIM_SUM} USD`);

    expect(TEST_DIVIDEND_SUM).not.equal(0);
  });

  it("CLAIM DIVIDEND FROM USERS", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== CLAIM DIVIDEND FROM USERS =========`);

    let TEST_USER_NFT_BALANCE_SUM = 0;
    let TEST_USER_CLAIM_SUM = 0;
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      try {
        // user claim dividend money
        await NFTContractForShareholder[i].claimBenefit(NFT_ID);
      } catch (error) {
        console.log("\x1b[35m%s\x1b[0m", `Claim FAIL: User ${i} : Error: ${error}`);
      }

      // check NFT balance after transfer
      let NFTbalance = await NFTContract.balanceOf(shareholder[i].address, NFT_ID);
      TEST_USER_NFT_BALANCE_SUM += parseInt(NFTbalance);

      // dividend info
      let getClaimedYield = parseInt(
        ethers.utils.formatEther(await NFTContractForShareholder[i].getClaimedYield(NFT_ID))
      );
      console.log(`User ${i}: NFTbalance: ${NFTbalance} NFT, getClaimedYield: ${getClaimedYield} USD`);

      TEST_USER_CLAIM_SUM += getClaimedYield;
    }
    console.log("\x1b[35m%s\x1b[0m", `TEST_NFT_SUM: ${TEST_NFT_SUM} NFT`);
    console.log("\x1b[35m%s\x1b[0m", `TEST_USER_NFT_BALANCE_SUM: ${TEST_USER_NFT_BALANCE_SUM} NFT`);

    console.log("\x1b[33m%s\x1b[0m", `TEST_DIVIDEND_SUM: ${TEST_DIVIDEND_SUM} USD`);
    console.log("\x1b[33m%s\x1b[0m", `TEST_USER_CLAIM_SUM: ${TEST_USER_CLAIM_SUM} USD`);

    expect(TEST_USER_CLAIM_SUM).equal(TEST_DIVIDEND_SUM);
  });
});
