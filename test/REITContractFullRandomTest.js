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
let TEST_USER_CLAIM_DIVIDEND_SUM = 0;

const TEST_REIT_DATA_URL = "ipfs://QmZ485APXNEhzLAtXccy5S78nMg83xBYJYXPSKtRVo8wy8";

// const [governor, creator, shareholder1, shareholder2, shareholder3] = await ethers.getSigners();
let governor;
let creator;
let shareholder = [];
let shareholderAddress = [];
const SHAREHOLDER_COUNT = 8;

let MEIContract;
let MEIContractForShareholder = [];

let USDContract;
let USDContractForShareholder = [];

let NFTContract;
let NFTContractForCreator;
let NFTContractForGovernor;
let NFTContractForShareholder = [];
const NFT_ID = 1;
const NFT_TRANSFER_MIN = 10;
const NFT_TRANSFER_MAX = 100;

let IPOContract;
let IPOContractForShareholder = [];

const TEST_MONTHS = 12;

const LOYALTY = {
  Condition: [0, ethers.utils.parseEther("8000"), ethers.utils.parseEther("40000"), ethers.utils.parseEther("80000"), ethers.utils.parseEther("200000")],
  PurchaseLimit: [200, 1000, 5000, 1200, 3000],
  TransferTaxes: [0.2 * Math.pow(10, 6), 0.18 * Math.pow(10, 6), 0.16 * Math.pow(10, 6), 0.14 * Math.pow(10, 6), 0.12 * Math.pow(10, 6)],
};
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
      shareholderAddress.push(accounts[i].address);
    }
    expect(governor, creator, shareholder);
  });

  it("MEI", async function () {
    const MEIFactory = await ethers.getContractFactory("USDMToken", governor);
    MEIContract = await MEIFactory.deploy("MEI", "Mock MEI");
    await MEIContract.deployed();

    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      const contract = await attachContractForSigner("USDMToken", shareholder[i], MEIContract.address);
      MEIContractForShareholder.push(contract);
    }
    expect(MEIContract.address);
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
    NFTContract = await upgrades.deployProxy(NFTFactory, ["Metain REIT", "MREIT", "ipfs://Qme41Gw4qAttT7ZB2o6KVjYxu5LFMihG9aiZvMQLkhPjB3"]);
    await NFTContract.deployed();

    await NFTContract.setupLoyaltyProgram(MEIContract.address, moment.duration(1, "y").asSeconds());
    await NFTContract.setLoyaltyConditions(LOYALTY.Condition);

    NFTContractForCreator = await attachContractForSigner("REITNFT", creator, NFTContract.address);
    NFTContractForGovernor = await attachContractForSigner("REITNFT", governor, NFTContract.address);

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
    const ipoContractAddress = await NFTContract.getIPOContract(NFT_ID);
    expect(ipoContractAddress).equal(IPOContract.address);
  });

  it("Setup NFT Trust", async function () {
    await IPOContract.allowPayableToken("USDT", USDContract.address);
    await IPOContract.setPurchaseLimits(NFT_ID, LOYALTY.PurchaseLimit);

    const now = Math.floor(Date.now() / 1000);
    await NFTContractForCreator.initiateREIT(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, LOYALTY.TransferTaxes);
    await NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, NFT_ID, TEST_REIT_AMOUNT, []);
    const ipoBalance = await NFTContract.balanceOf(IPOContract.address, NFT_ID);
    expect(ipoBalance).equal(TEST_REIT_AMOUNT);
  });
});

// The Timeout for a test case is 40000ms, so we need perform the test in many steps
describe("NFT/IPO RAMDOM TEST", function () {
  it("KYC => staking => BUY NFT", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== KYC => staking => BUY NFT =========`);
    TEST_NFT_SUM = 0;
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      // transfer USDT/MEI for Users
      await USDContract.transfer(shareholder[i].address, TEST_SHARE_HOLDER_FUND);
      await MEIContract.transfer(shareholder[i].address, TEST_SHARE_HOLDER_FUND);
      // allow IPOContract get USDT/MEI from users
      await USDContractForShareholder[i].increaseAllowance(IPOContract.address, TEST_SHARE_HOLDER_FUND);
      await USDContractForShareholder[i].increaseAllowance(NFTContract.address, TEST_SHARE_HOLDER_FUND);
      await MEIContractForShareholder[i].increaseAllowance(NFTContract.address, TEST_SHARE_HOLDER_FUND);

      // KYC users
      await NFTContract.addToKYC(shareholder[i].address);

      // stake will level 3
      await NFTContractForShareholder[i].stake(LOYALTY.Condition[3]);

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
    await NFTContract.fundDividendVault(NFT_ID, ethers.utils.parseEther("100000000"));

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
        await NFTContractForShareholder[TRANSFER_FROM].safeTransferFrom(shareholder[TRANSFER_FROM].address, shareholder[TRANSFER_TO].address, NFT_ID, TRANSFER_AMOUNT, []);
        console.log(`Transfer SUCCESS: ${TRANSFER_AMOUNT} NFT from User ${TRANSFER_FROM} to User ${TRANSFER_TO}`);

        NFTlockingBalance = await NFTContract.lockedBalanceOf(shareholder[TRANSFER_TO].address, NFT_ID);
        console.log(`User  ${TRANSFER_TO}: NFT locking balance after transfer: ${NFTlockingBalance}`);
      } catch (error) {
        console.log("\x1b[35m%s\x1b[0m", `Transfer FAIL: ${TRANSFER_AMOUNT} NFT from User ${TRANSFER_FROM} to User ${TRANSFER_TO}`);
        console.log("\x1b[35m%s\x1b[0m", `Error: ${error}`);
      }

      // Admin unlock Dividends fund for monthS and set Dividends for per user
      await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther(DIVIDEND_AMOUNT.toString()), i);
      TEST_DIVIDEND_SUM += parseInt(DIVIDEND_AMOUNT * TEST_NFT_SUM);

      // get Dividends info of month
      const getDividendPerShare = await NFTContractForCreator.getDividendPerShare(NFT_ID, i);
      console.log(`Unlocked getDividendPerShare: ${getDividendPerShare} USD`);

      // check Dividends info before redeemLockedBalances
      let getLockedDividends = parseInt(ethers.utils.formatEther(await NFTContractForShareholder[TRANSFER_TO].getLockedDividends(NFT_ID)));
      console.log(`User ${TRANSFER_TO}: getLockedDividends after Unlock Dividend: ${getLockedDividends} USD`);

      dividendClaim = parseInt(ethers.utils.formatEther(await NFTContractForShareholder[TRANSFER_TO].getTotalClaimableDividends(NFT_ID)));
      if (dividendClaim > 0) {
        console.log(`User ${TRANSFER_TO}: Try to claim ${dividendClaim} USD after Unlock Dividend`);
        // try to claim before redeemLockedBalances
        await NFTContractForShareholder[TRANSFER_TO].claimDividends(NFT_ID);
        TEST_USER_CLAIM_DIVIDEND_SUM += dividendClaim;
      }

      if (NFTlockingBalance > 0) {
        // register NFT after transfer success
        await NFTContractForShareholder[TRANSFER_TO].redeemLockedBalances(NFT_ID);
      }
    }

    // get Total Dividend
    const getTotalDividendPerShare = await NFTContractForCreator.getTotalDividendPerShare(NFT_ID);
    console.log(`Unlocked getTotalDividendPerShare: ${getTotalDividendPerShare} USD`);

    console.log("\x1b[33m%s\x1b[0m", `TEST_DIVIDEND_SUM after ${TEST_MONTHS} months: ${TEST_DIVIDEND_SUM} USD`);
    console.log("\x1b[33m%s\x1b[0m", `TEST_USER_CLAIM_DIVIDEND_SUM: ${TEST_USER_CLAIM_DIVIDEND_SUM} USD`);

    expect(TEST_DIVIDEND_SUM).not.equal(0);
  });

  it("CLAIM DIVIDEND FROM USERS", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== CLAIM DIVIDEND FROM USERS =========`);

    let TEST_USER_NFT_BALANCE_SUM = 0;
    let TEST_USER_CLAIM_DIVIDEND_SUM = 0;
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      try {
        // user claim dividend money
        await NFTContractForShareholder[i].claimDividends(NFT_ID);
      } catch (error) {
        console.log("\x1b[35m%s\x1b[0m", `Claim FAIL: User ${i} : Error: ${error}`);
      }

      // check NFT balance after transfer
      let NFTbalance = await NFTContract.balanceOf(shareholder[i].address, NFT_ID);
      TEST_USER_NFT_BALANCE_SUM += parseInt(NFTbalance);

      // dividend info
      let getClaimedDividends = parseInt(ethers.utils.formatEther(await NFTContractForShareholder[i].getClaimedDividends(NFT_ID)));
      console.log(`User ${i}: NFTbalance: ${NFTbalance} NFT, getClaimedDividends: ${getClaimedDividends} USD`);

      TEST_USER_CLAIM_DIVIDEND_SUM += getClaimedDividends;
    }
    console.log("\x1b[35m%s\x1b[0m", `TEST_NFT_SUM: ${TEST_NFT_SUM} NFT`);
    console.log("\x1b[35m%s\x1b[0m", `TEST_USER_NFT_BALANCE_SUM: ${TEST_USER_NFT_BALANCE_SUM} NFT`);

    console.log("\x1b[33m%s\x1b[0m", `TEST_DIVIDEND_SUM: ${TEST_DIVIDEND_SUM} USD`);
    console.log("\x1b[33m%s\x1b[0m", `TEST_USER_CLAIM_DIVIDEND_SUM: ${TEST_USER_CLAIM_DIVIDEND_SUM} USD`);

    expect(TEST_USER_CLAIM_DIVIDEND_SUM).equal(TEST_DIVIDEND_SUM);
  });

  it("WITHDRAW DIVIDEND VAULT", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== WITHDRAW DIVIDEND VAULT =========`);

    const usdBalance_before = parseInt(ethers.utils.formatEther((await USDContract.balanceOf(NFTContract.address))));
    console.log(`NFTContract: USD balance before withdraw: ${usdBalance_before} USD`);

    const WITHDRAW_DIVIDEND_AMOUNT = "1000";
    await NFTContractForGovernor.withdrawDividendVault(NFT_ID, ethers.utils.parseEther(WITHDRAW_DIVIDEND_AMOUNT), governor.address);

    const usdBalance_after = parseInt(ethers.utils.formatEther((await USDContract.balanceOf(NFTContract.address))));
    console.log(`NFTContract: USD balance after withdraw: ${usdBalance_after} USD`);

    const withdraw_value = usdBalance_before - usdBalance_after;
    console.log("\x1b[33m%s\x1b[0m", `withdraw_value: ${withdraw_value} USD`);

    expect(withdraw_value).not.equal(0);
  });

  it("CLAIM LIQUIDATIONS FROM USERS", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== CLAIM LIQUIDATIONS FROM USERS =========`);

    const LIQUIDATIONS_AMOUNT = 10;

    // Asset manager pays dividend, each NFT will receive $1
    // allow NFTContract get USDT from USDContract
    await USDContract.increaseAllowance(NFTContract.address, ethers.utils.parseEther("1000000"));
    // Admin transfer payable tokens for Liquidations
    await NFTContract.fundLiquidationVault(NFT_ID, ethers.utils.parseEther("1000000"));
    // Admin unlock Liquidations for users
    await NFTContractForCreator.unlockLiquidationPerShare(NFT_ID, ethers.utils.parseEther(LIQUIDATIONS_AMOUNT.toString()));
    // Admin unlock Liquidations for users
    await NFTContractForCreator.allowLiquidationClaims(NFT_ID, shareholderAddress);

    let TEST_LIQUIDATIONS_SUM = TEST_NFT_SUM * LIQUIDATIONS_AMOUNT;
    let TEST_USER_CLAIM_LIQUIDATIONS_SUM = 0;
    for (let i = 0; i < SHAREHOLDER_COUNT; ++i) {
      let getClaimableLiquidations = parseInt(ethers.utils.formatEther(await NFTContractForShareholder[i].getClaimableLiquidations(NFT_ID)));
      console.log(`User ${i}: getClaimableLiquidations after Unlock: ${getClaimableLiquidations} USD`);

      // user claim Liquidations money
      await NFTContractForShareholder[i].claimLiquidations(NFT_ID);

      let getClaimedLiquidations = parseInt(ethers.utils.formatEther(await NFTContractForShareholder[i].getClaimedLiquidations(NFT_ID)));
      console.log(`User ${i}: getClaimedLiquidations: ${getClaimedLiquidations} USD`);

      if (getClaimableLiquidations == getClaimedLiquidations) {
        TEST_USER_CLAIM_LIQUIDATIONS_SUM += getClaimedLiquidations;
      }
    }
    console.log("\x1b[33m%s\x1b[0m", `TEST_DIVIDEND_SUM: ${TEST_LIQUIDATIONS_SUM} USD`);
    console.log("\x1b[33m%s\x1b[0m", `TEST_USER_CLAIM_LIQUIDATIONS_SUM: ${TEST_USER_CLAIM_LIQUIDATIONS_SUM} USD`);

    expect(TEST_USER_CLAIM_LIQUIDATIONS_SUM).equal(TEST_LIQUIDATIONS_SUM);
  });

  it("WITHDRAW LIQUIDATION VAULT", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\n=========== WITHDRAW LIQUIDATION VAULT =========`);

    const usdBalance_before = parseInt(ethers.utils.formatEther(await USDContract.balanceOf(NFTContract.address)));
    console.log(`NFTContract: USD balance before withdraw: ${usdBalance_before} USD`);

    const WITHDRAW_DIVIDEND_AMOUNT = "1000";
    await NFTContractForGovernor.withdrawLiquidationVault(NFT_ID, ethers.utils.parseEther(WITHDRAW_DIVIDEND_AMOUNT), governor.address);

    const usdBalance_after = parseInt(ethers.utils.formatEther((await USDContract.balanceOf(NFTContract.address))));
    console.log(`NFTContract: USD balance after withdraw: ${usdBalance_after} USD`);

    const withdraw_value = usdBalance_before - usdBalance_after;
    console.log("\x1b[33m%s\x1b[0m", `withdraw_value: ${withdraw_value} USD`);

    expect(withdraw_value).not.equal(0);
  });
});