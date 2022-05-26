const os = require("os");
const moment = require("moment");
const path = require("path");
const fs = require("fs");

const readline = require("readline");

const PROXY_CONTRACT_ADDRESS = "0xe590c081c18297699d0A3a300Ee3A72f137EeeBA";

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
    const res = await eval(`contract.${command}`);
    console.log(res);
  } catch (ex) {
    console.error(ex);
  }
}

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Signer", owner.address);

  const Token = await ethers.getContractFactory('ERC1155Tradable');    
  const contract = Token.attach(PROXY_CONTRACT_ADDRESS);

  console.log("Enter JS command");

  while (true) {
    const command = await prompt("> ");
    switch (command) {
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

main();
