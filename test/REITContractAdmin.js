const moment = require("moment");
const { expect, use } = require("chai");
const { solidity } = require("ethereum-waffle");

const env = require("../env.json")["dev"];

use(solidity);

const TEST_REIT_AMOUNT = 200000;
const TEST_REIT_UNIT_PRICE = ethers.utils.parseEther("10");
const TEST_SHARE_HOLDER_FUND = ethers.utils.parseEther("100000");
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

console.log("\x1b[33m%s\x1b[0m", "\n================== TEST ADMIN FUNCTIONS ==================");

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
    NFTContract = await upgrades.deployProxy(NFTFactory, ["Metain REIT", "MREIT", "ipfs://Qme41Gw4qAttT7ZB2o6KVjYxu5LFMihG9aiZvMQLkhPjB3"]);
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
    const ipoContractAddress = await NFTContract.getIPOContract(NFT_ID);
    expect(ipoContractAddress).equal(IPOContract.address);
  });

  it("Setup NFT Trust", async function () {
    await IPOContract.allowPayableToken("USDT", USDContract.address);

    const now = Math.floor(Date.now() / 1000);
    await NFTContractForCreator.initiateREIT(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, 2);
    await NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, NFT_ID, TEST_REIT_AMOUNT, []);
    const ipoBalance = await NFTContract.balanceOf(IPOContract.address, NFT_ID);
    expect(ipoBalance).equal(TEST_REIT_AMOUNT);
  });

  it("Normal User try setup IPOContract", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try setup IPOContract`);
    let error;
    try {
      await NFTContractForShareholder[0].setIPOContract(NFT_ID, IPOContract.address);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try initiate REIT", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try initiate REIT`);
    await IPOContract.allowPayableToken("USDT", USDContract.address);
    let error;
    try {
      const now = Math.floor(Date.now() / 1000);
      await NFTContractForShareholder[0].initiateREIT(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, 2);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try setUnitMarketValue", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try setUnitMarketValue`);
    let error;
    try {
      await NFTContractForShareholder[0].setUnitMarketValue(NFT_ID, ethers.utils.parseEther("10"));
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });
});

describe("Buying IPO", function () {
  it("Normal User try KYC", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try KYC`);
    let error;
    try {
      await NFTContractForShareholder[0].addToKYC(shareholder[0].address);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try revokeKYCAdmin", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try revokeKYCAdmin`);
    let error;
    try {
      await NFTContractForShareholder[0].revokeKYCAdmin();
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try to unlockDividendPerShare", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try to unlockDividendPerShare`);
    let error;
    try {
      await NFTContractForShareholder[0].unlockDividendPerShare(NFT_ID, ethers.utils.parseEther("2"), 0);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try to unlockLiquidationPerShare", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try to unlockLiquidationPerShare`);
    let error;
    try {
      await NFTContractForShareholder[0].unlockLiquidationPerShare(NFT_ID, ethers.utils.parseEther("2"));
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try to lockLiquidationPerShare", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try to lockLiquidationPerShare`);
    let error;
    try {
      await NFTContractForShareholder[0].lockLiquidationPerShare(NFT_ID);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try to allowLiquidationClaims", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try to allowLiquidationClaims`);
    let error;
    try {
      await NFTContractForShareholder[0].allowLiquidationClaims(NFT_ID, [shareholder[0].address]);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try to holdLiquidationClaims", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try to holdLiquidationClaims`);
    let error;
    try {
      await NFTContractForShareholder[0].holdLiquidationClaims(NFT_ID, [shareholder[0].address]);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try to withdrawDividendVault", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try to withdrawDividendVault`);
    let error;
    try {
      await NFTContractForShareholder[0].withdrawDividendVault(NFT_ID, ethers.utils.parseEther("1000"), shareholder[0].address);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });

  it("Normal User try to withdrawLiquidationVault", async function () {
    console.log("\x1b[33m%s\x1b[0m", `\nNormal User try to withdrawLiquidationVault`);
    let error;
    try {
      await NFTContractForShareholder[0].withdrawLiquidationVault(NFT_ID, ethers.utils.parseEther("1000"), shareholder[0].address);
    } catch (ex) {
      console.log(`ex: ${ex}`);
      error = ex;
    }
    expect(error);
  });
});
