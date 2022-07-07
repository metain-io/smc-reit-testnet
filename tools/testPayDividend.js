const fs = require("fs");
const path = require("path");
const moment = require("moment");

const argv = require("minimist")(process.argv.slice(2));

async function attachContractForSigner(name, signer, address) {
  const factory = await ethers.getContractFactory(name, signer);
  return factory.attach(address);
}

module.exports = async function () {  
  const NFT_ID = 1;
  const amount = argv.amount || 1000;
  const share = argv.share || 1;
  const dividendTimeIndex = argv.time || 0;

  const [governor, creator] = await ethers.getSigners();

  const deployedUSDData = JSON.parse(
    fs.readFileSync(path.join(__dirname, `../test/deployed-usd-${argv.network}.json`), "utf-8")
  );
  const USDAddress = deployedUSDData.MUSDT;

  const deployedNFTData = JSON.parse(
    fs.readFileSync(path.join(__dirname, `../test/deployed-nft-${argv.network}.json`), "utf-8")
  );
  const NFTAddress = deployedNFTData.proxy;

  const USDContract = await attachContractForSigner("USDMToken", governor, USDAddress);
  const NFTContract = await attachContractForSigner("REITNFT", governor, NFTAddress);
  const NFTContractForCreator = await attachContractForSigner("REITNFT", creator, NFTAddress);

  await USDContract.increaseAllowance(NFTAddress, ethers.utils.parseEther("1000000000"));
  await NFTContract.fundDividendVault(NFT_ID, ethers.utils.parseEther(amount.toString()));
  await NFTContractForCreator.unlockDividendPerShare(NFT_ID, ethers.utils.parseEther(share.toString()), dividendTimeIndex);
};
