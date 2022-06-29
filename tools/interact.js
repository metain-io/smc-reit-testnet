const os = require("os");
const moment = require("moment");
const path = require("path");
const fs = require("fs");

const readline = require("readline");
const argv = require("minimist")(process.argv.slice(2));

const TEST_REIT_DATA_URL = "ipfs://QmZ485APXNEhzLAtXccy5S78nMg83xBYJYXPSKtRVo8wy8";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function prompt(message) {
  return new Promise((resolve, reject) => {
    rl.question(message, function (result) {
      resolve(result);
    });
  });
}

async function runMethod(contract, command) {
  try {
    console.log("Run:", command, "...");
    const transaction = await eval(`contract.${command}`);
    if (transaction.wait) {
      const receipt = await transaction.wait();
      console.log(receipt);
    } else {
      console.log(transaction);
    }
  } catch (ex) {
    console.error(ex);
  }
}

async function interactIPO () {
  const [owner, creator, buyer] = await ethers.getSigners();
  console.log("Signer", owner.address);

  const deployedData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-ipo-${argv.network}.json`), 'utf-8'));
  console.log("Proxy contract address:", deployedData.proxy);  
  
  const Contract = await ethers.getContractFactory("REITIPO");
  const contract = Contract.attach(deployedData.proxy);    

  const ContractForBuyer = await ethers.getContractFactory("REITIPO", buyer);
  const contractForBuyer = ContractForBuyer.attach(deployedData.proxy);    

  while (true) {
    console.log("Enter JS command:");
    console.log("a) Allow mock USD tokens");
    console.log("b) Buy REIT NFT");
    console.log("f) Fund buyer with USDT");
    
    const command = await prompt("> ");
    switch (command) {
      case "a": {
        const mockUSDData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-usd-${argv.network}.json`), 'utf-8'));
        for (let name in mockUSDData) {
          await runMethod(contract, `allowPayableToken("${name}", "${mockUSDData[name]}")`);
        }
        break;
      }

      case "b": {
        await runMethod(contract, `addToWhitelisted("${buyer.address}")`);
        await runMethod(contractForBuyer, `purchaseWithToken("MUSDT", 10)`);
        break;
      }

      case "f": {
        const mockUSDData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-usd-${argv.network}.json`), 'utf-8'));
        const USDTContract = await ethers.getContractFactory("USDMToken", owner);
        const contractUSDT = USDTContract.attach(mockUSDData.MUSDT);

        await contractUSDT.transfer(buyer.address, ethers.utils.parseEther("1000000"));
        const balance = await contractUSDT.balanceOf(buyer.address);
        console.log('Balance of buyer:', balance.toString());
        
        await contractUSDT.approve(deployedData.proxy, ethers.utils.parseEther("1000000"));
        break;
      }

      case "q": {
        process.exit();
      }

      default: {
        await runMethod(contract, command);
        break;
      }
    }
  }
}

async function interactNFT () {
  const [owner, creator] = await ethers.getSigners();
  console.log("Signer", owner.address);

  const deployedData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-nft-${argv.network}.json`), 'utf-8'));
  console.log("Proxy contract address:", deployedData.address);
  
  const Token = await ethers.getContractFactory("REITNFT");
  const contract = Token.attach(deployedData.proxy);  

  const TokenForCreator = await ethers.getContractFactory("REITNFT", creator);
  const contractForCreator = TokenForCreator.attach(deployedData.proxy);  

  while (true) {
    console.log("Enter JS command:");
    console.log("c) Create test NFT");
    console.log("i) Transfer all NFT to IPO");

    const command = await prompt("> ");
    switch (command) {
      case "c": {
        await runMethod(contract, `create("${creator.address}",250000,"${TEST_REIT_DATA_URL}","0x9ce4cd6D7f5e8b14c7a3e8e6A257A86Bd5a6EeA0",[])`);
        break;
      }

      case "i": {
        const deployedIPOData = JSON.parse(fs.readFileSync(path.join(__dirname, `../test/deployed-ipo-${argv.network}.json`), 'utf-8'));
        await runMethod(contractForCreator, `safeTransferFrom("${creator.address}","${deployedIPOData.proxy}",1,250000,[])`);
        break;
      }

      case "q": {
        process.exit();
      }

      default: {
        await runMethod(contract, command);
        break;
      }
    }
  }
}

async function interactUSD () {
  const [owner, creator] = await ethers.getSigners();
  console.log("Signer", owner.address);

  const USDMAddress = "0xEf082A75d42A11B8B2c7eF8F969CEAba39eD551c";
  
  const Token = await ethers.getContractFactory("USDMToken");
  const contract = Token.attach(USDMAddress);  

  const TokenForCreator = await ethers.getContractFactory("USDMToken", creator);
  const contractForCreator = TokenForCreator.attach(USDMAddress);  

  while (true) {
    console.log("Enter JS command:");

    const command = await prompt("> ");
    switch (command) {

      default: {
        await runMethod(contract, command);
        break;
      }
    }
  }
}

module.exports = async function main() {
  console.log("Select contract to interact:");
  console.log("1) REIT NFT");
  console.log("2) REIT IPO");
  console.log("3) USD Token");

  const selection = await prompt("> ");

  switch (selection) {
    case "2":
      await interactIPO();

    case "3":
      await interactUSD();

    default:
      await interactNFT();  
  }  
}
