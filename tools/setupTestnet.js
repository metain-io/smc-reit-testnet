const fs = require("fs");
const path = require("path");
const moment = require("moment");

const argv = require("minimist")(process.argv.slice(2));

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);
}

async function txCompletion (txPromise) {
  const tx = await txPromise;
  return tx.wait();
}

module.exports = async function () {
  const TEST_REIT_AMOUNT = 200000;
  const TEST_REIT_DATA_URL = "ipfs://QmZ485APXNEhzLAtXccy5S78nMg83xBYJYXPSKtRVo8wy8";
  const TEST_REIT_UNIT_PRICE = ethers.utils.parseEther("10");
  const NFT_ID = 1;

  const [governor, creator] = await ethers.getSigners();

  const deployedUSDData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-usd-${argv.network}.json`), "utf-8"));
  const USDAddress = deployedUSDData.MUSDT;

  const deployedNFTData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-nft-${argv.network}.json`), "utf-8"));
  const NFTAddress = deployedNFTData.proxy;

  const deployedIPOData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-ipo-${argv.network}.json`), "utf-8"));
  const IPOAddress = deployedIPOData.proxy;

  const NFTContract = await attachContractForSigner("REITNFT", governor, NFTAddress);
  const NFTContractForCreator = await attachContractForSigner("REITNFT", creator, NFTAddress);
  const IPOContract = await attachContractForSigner("REITIPO", governor, IPOAddress);

  let ipoBalance = (await NFTContractForCreator.balanceOf(IPOContract.address, NFT_ID)).toString();  

  if (parseInt(ipoBalance.toString()) <= 0) {
    const creationResult = await txCompletion(NFTContract.createREIT(creator.address, TEST_REIT_AMOUNT, TEST_REIT_DATA_URL, USDAddress, []));
    console.log(creationResult.events.filter((evt) => evt.event === "Create"));
    
    const now = Math.floor(Date.now() / 1000);
    await txCompletion(NFTContractForCreator.initiateREIT(NFT_ID, now, TEST_REIT_UNIT_PRICE.toString(), now + 30 * 3600, [
      0.2 * Math.pow(10, 6),
      0.18 * Math.pow(10, 6),
      0.16 * Math.pow(10, 6),
      0.14 * Math.pow(10, 6),
      0.12 * Math.pow(10, 6)
    ]));
    await txCompletion(NFTContractForCreator.setIPOContract(NFT_ID, IPOAddress));    
    await txCompletion(NFTContractForCreator.safeTransferFrom(creator.address, IPOContract.address, NFT_ID, TEST_REIT_AMOUNT, []));

    ipoBalance = (await NFTContractForCreator.balanceOf(IPOContract.address, NFT_ID)).toString();  
  }

  await IPOContract.allowPayableToken("USDT", USDAddress);
  await IPOContract.setPurchaseLimits([200, 1000, 5000, 1200, 3000]);

  console.log("IPO Balance:", ipoBalance);
};
