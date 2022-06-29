const fs = require("fs");
const path = require("path");
const moment = require("moment");

const argv = require("minimist")(process.argv.slice(2));

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);
}

module.exports = async function () {
  const TEST_REIT_AMOUNT = 200000;
  const TEST_REIT_DATA_URL = "ipfs://QmZ485APXNEhzLAtXccy5S78nMg83xBYJYXPSKtRVo8wy8";
  const TEST_REIT_UNIT_PRICE = ethers.utils.parseEther("10");
  const NFT_ID = 1;

  const [governor, creator] = await ethers.getSigners();

  const USDAddress = "0xEf082A75d42A11B8B2c7eF8F969CEAba39eD551c";

  const deployedNFTData = JSON.parse(
    fs.readFileSync(path.join(__dirname, `../test/deployed-nft-${argv.network}.json`), "utf-8")
  );
  const NFTAddress = deployedNFTData.proxy;

  const deployedIPOData = JSON.parse(
    fs.readFileSync(path.join(__dirname, `../test/deployed-ipo-${argv.network}.json`), "utf-8")
  );
  const IPOAddress = deployedIPOData.proxy;

  const NFTContract = await attachContractForSigner("REITNFT", governor, NFTAddress);
  const NFTContractForCreator = await attachContractForSigner("REITNFT", creator, NFTAddress);
  const IPOContract = await attachContractForSigner("REITIPO", governor, IPOAddress);

  const ipoBalance = (await NFTContractForCreator.balanceOf(IPOContract.address, 1)).toString();  

  if (parseInt(ipoBalance.toString()) <= 0) {
    await NFTContract.createREIT(creator.address, TEST_REIT_AMOUNT, TEST_REIT_DATA_URL, USDAddress, []);
    await NFTContractForCreator.setIPOContract(NFT_ID, IPOAddress);

    await IPOContract.allowPayableToken("USDT", USDAddress);

    const now = Math.floor(Date.now() / 1000);
    await NFTContractForCreator.initiate(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, 2);
    await NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, NFT_ID, TEST_REIT_AMOUNT, []);
  }

  console.log("IPO Balance:", ipoBalance);
};
